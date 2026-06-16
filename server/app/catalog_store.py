from __future__ import annotations

import json
import shutil
import sqlite3
from contextlib import closing, contextmanager
from datetime import date
from pathlib import Path
from threading import Lock
from typing import Iterator

from .schemas import (
    CatalogAuditEvent,
    CatalogProduct,
    ReviewRecord,
    ReviewStatus,
)


class CatalogWorkflowError(ValueError):
    pass


class CatalogStore:
    def __init__(self, database_path: Path) -> None:
        self._database_path = database_path
        self._lock = Lock()
        self._initialize()

    @contextmanager
    def _connect(self) -> Iterator[sqlite3.Connection]:
        connection = sqlite3.connect(self._database_path)
        connection.row_factory = sqlite3.Row
        try:
            with connection:
                yield connection
        finally:
            connection.close()

    def _initialize(self) -> None:
        self._database_path.parent.mkdir(parents=True, exist_ok=True)
        with self._connect() as connection:
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS catalog_products (
                    id TEXT PRIMARY KEY,
                    review_status TEXT NOT NULL,
                    payload TEXT NOT NULL,
                    updated_at TEXT NOT NULL,
                    updated_by TEXT NOT NULL
                )
                """
            )
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS catalog_audit_log (
                    audit_id INTEGER PRIMARY KEY AUTOINCREMENT,
                    product_id TEXT NOT NULL,
                    action TEXT NOT NULL,
                    review_status TEXT NOT NULL,
                    operator TEXT NOT NULL,
                    note TEXT NOT NULL,
                    changed_at TEXT NOT NULL
                )
                """
            )

    def list(self, status: ReviewStatus | None = None) -> list[CatalogProduct]:
        query = "SELECT payload FROM catalog_products"
        parameters: tuple[str, ...] = ()
        if status is not None:
            query += " WHERE review_status = ?"
            parameters = (status.value,)
        query += " ORDER BY updated_at DESC"
        with self._connect() as connection:
            rows = connection.execute(query, parameters).fetchall()
        return [
            CatalogProduct.model_validate(json.loads(row["payload"]))
            for row in rows
        ]

    def published(self) -> list[CatalogProduct]:
        return [
            product
            for product in self.list()
            if product.reviewStatus in {ReviewStatus.reviewed, ReviewStatus.verified}
        ]

    def get(self, product_id: str) -> CatalogProduct | None:
        with self._connect() as connection:
            row = connection.execute(
                "SELECT payload FROM catalog_products WHERE id = ?",
                (product_id,),
            ).fetchone()
        if row is None:
            return None
        return CatalogProduct.model_validate(json.loads(row["payload"]))

    def audit_log(
        self,
        product_id: str | None = None,
        *,
        limit: int = 100,
    ) -> list[CatalogAuditEvent]:
        query = """
            SELECT audit_id, product_id, action, review_status,
                   operator, note, changed_at
            FROM catalog_audit_log
        """
        parameters: tuple[object, ...]
        if product_id is None:
            parameters = (limit,)
        else:
            query += " WHERE product_id = ?"
            parameters = (product_id, limit)
        query += " ORDER BY audit_id DESC LIMIT ?"
        with self._connect() as connection:
            rows = connection.execute(query, parameters).fetchall()
        return [
            CatalogAuditEvent(
                auditId=row["audit_id"],
                productId=row["product_id"],
                action=row["action"],
                reviewStatus=ReviewStatus(row["review_status"]),
                operator=row["operator"],
                note=row["note"],
                changedAt=row["changed_at"],
            )
            for row in rows
        ]

    def backup_to(self, destination: Path) -> None:
        destination.parent.mkdir(parents=True, exist_ok=True)
        with self._lock:
            with self._connect() as source:
                with closing(sqlite3.connect(destination)) as target:
                    source.backup(target)

    def integrity_report(self) -> dict[str, int | str]:
        with self._connect() as connection:
            integrity = connection.execute("PRAGMA integrity_check").fetchone()[0]
            product_count = connection.execute(
                "SELECT COUNT(*) FROM catalog_products"
            ).fetchone()[0]
            audit_count = connection.execute(
                "SELECT COUNT(*) FROM catalog_audit_log"
            ).fetchone()[0]
        return {
            "integrity": integrity,
            "products": product_count,
            "auditEvents": audit_count,
        }

    def restore_drill(self, backup_path: Path, destination: Path) -> dict[str, int | str]:
        if not backup_path.is_file():
            raise CatalogWorkflowError(f"Backup file not found: {backup_path}")
        if destination.exists():
            raise CatalogWorkflowError(
                f"Restore destination already exists: {destination}"
            )

        source_report = CatalogStore(backup_path).integrity_report()
        if source_report["integrity"] != "ok":
            raise CatalogWorkflowError("Backup database integrity check failed.")

        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(backup_path, destination)
        restored_report = CatalogStore(destination).integrity_report()
        if restored_report != source_report:
            destination.unlink(missing_ok=True)
            raise CatalogWorkflowError("Restored database does not match backup.")
        return restored_report

    def upsert(
        self,
        product: CatalogProduct,
        *,
        operator: str,
        note: str,
    ) -> CatalogProduct:
        existing = self.get(product.id)
        if existing is not None and existing.reviewStatus != ReviewStatus.draft:
            raise CatalogWorkflowError(
                "Reviewed products must return to draft before content edits."
            )
        if product.reviewStatus != ReviewStatus.draft:
            raise CatalogWorkflowError("New or edited products must be draft.")
        self._validate_history(product)
        self._save(product, operator=operator, action="upsert", note=note)
        return product

    def transition(
        self,
        product_id: str,
        *,
        target: ReviewStatus,
        operator: str,
        note: str,
    ) -> CatalogProduct:
        product = self.get(product_id)
        if product is None:
            raise KeyError(product_id)
        allowed = {
            ReviewStatus.draft: {ReviewStatus.reviewed},
            ReviewStatus.reviewed: {
                ReviewStatus.draft,
                ReviewStatus.verified,
            },
            ReviewStatus.verified: {ReviewStatus.draft},
        }
        if target not in allowed[product.reviewStatus]:
            raise CatalogWorkflowError(
                f"Cannot transition {product.reviewStatus.value} to {target.value}."
            )
        updated = product.model_copy(
            update={
                "reviewStatus": target,
                "reviewedBy": operator,
                "reviewNote": note,
                "reviewHistory": [
                    *product.reviewHistory,
                    ReviewRecord(
                        status=target,
                        reviewer=operator,
                        reviewedAt=date.today(),
                        note=note,
                    ),
                ],
            }
        )
        self._save(
            updated,
            operator=operator,
            action="transition",
            note=note,
        )
        return updated

    def delete_draft(self, product_id: str, *, operator: str) -> bool:
        product = self.get(product_id)
        if product is None:
            return False
        if product.reviewStatus != ReviewStatus.draft:
            raise CatalogWorkflowError("Only draft products can be deleted.")
        with self._lock, self._connect() as connection:
            connection.execute(
                "DELETE FROM catalog_products WHERE id = ?",
                (product_id,),
            )
            connection.execute(
                """
                INSERT INTO catalog_audit_log (
                    product_id, action, review_status, operator, note, changed_at
                ) VALUES (?, ?, ?, ?, ?, datetime('now'))
                """,
                (
                    product_id,
                    "delete",
                    product.reviewStatus.value,
                    operator,
                    "draft deleted",
                ),
            )
        return True

    def _save(
        self,
        product: CatalogProduct,
        *,
        operator: str,
        action: str,
        note: str,
    ) -> None:
        with self._lock, self._connect() as connection:
            connection.execute(
                """
                INSERT INTO catalog_products (
                    id, review_status, payload, updated_at, updated_by
                ) VALUES (?, ?, ?, datetime('now'), ?)
                ON CONFLICT(id) DO UPDATE SET
                    review_status = excluded.review_status,
                    payload = excluded.payload,
                    updated_at = excluded.updated_at,
                    updated_by = excluded.updated_by
                """,
                (
                    product.id,
                    product.reviewStatus.value,
                    json.dumps(
                        product.model_dump(mode="json", exclude_none=True),
                        ensure_ascii=False,
                    ),
                    operator,
                ),
            )
            connection.execute(
                """
                INSERT INTO catalog_audit_log (
                    product_id, action, review_status, operator, note, changed_at
                ) VALUES (?, ?, ?, ?, ?, datetime('now'))
                """,
                (
                    product.id,
                    action,
                    product.reviewStatus.value,
                    operator,
                    note,
                ),
            )

    def _validate_history(self, product: CatalogProduct) -> None:
        if product.reviewHistory[-1].status != product.reviewStatus:
            raise CatalogWorkflowError(
                "Last review history status must match reviewStatus."
            )
