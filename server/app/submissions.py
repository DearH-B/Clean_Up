import json
from datetime import UTC, datetime
from pathlib import Path
from threading import Lock
from uuid import uuid4

from .schemas import (
    SubmissionCreate,
    SubmissionResponse,
    SubmissionReviewEvent,
    SubmissionStatus,
)


class SubmissionStore:
    def __init__(self, data_path: Path) -> None:
        self._data_path = data_path
        self._lock = Lock()
        self._items = self._load()

    def _load(self) -> list[SubmissionResponse]:
        if not self._data_path.exists():
            return []
        raw_items = json.loads(self._data_path.read_text(encoding="utf-8"))
        return [SubmissionResponse.model_validate(item) for item in raw_items]

    def create(self, payload: SubmissionCreate) -> SubmissionResponse:
        with self._lock:
            existing = next(
                (
                    item
                    for item in self._items
                    if item.clientSubmissionId == payload.clientSubmissionId
                ),
                None,
            )
            if existing is not None:
                return existing

            now = datetime.now(UTC)
            item = SubmissionResponse(
                **payload.model_dump(),
                trackingToken=uuid4().hex,
                status=SubmissionStatus.received,
                statusMessage="운영팀 접수 대기열에 등록됐어요.",
                updatedAt=now,
                reviewHistory=[
                    SubmissionReviewEvent(
                        status=SubmissionStatus.received,
                        operator="system",
                        changedAt=now,
                        note="새 제보 접수",
                    )
                ],
            )
            self._items.insert(0, item)
            self._save()
            return item

    def get(self, tracking_token: str) -> SubmissionResponse | None:
        return next(
            (
                item
                for item in self._items
                if item.trackingToken == tracking_token
            ),
            None,
        )

    def list(
        self,
        status: SubmissionStatus | None = None,
    ) -> list[SubmissionResponse]:
        if status is None:
            return list(self._items)
        return [item for item in self._items if item.status == status]

    def update_status(
        self,
        tracking_token: str,
        *,
        status: SubmissionStatus,
        operator: str,
        note: str,
    ) -> SubmissionResponse | None:
        with self._lock:
            for index, item in enumerate(self._items):
                if item.trackingToken != tracking_token:
                    continue
                now = datetime.now(UTC)
                updated = item.model_copy(
                    update={
                        "status": status,
                        "statusMessage": note,
                        "updatedAt": now,
                        "reviewHistory": [
                            *item.reviewHistory,
                            SubmissionReviewEvent(
                                status=status,
                                operator=operator,
                                changedAt=now,
                                note=note,
                            ),
                        ],
                    }
                )
                self._items[index] = updated
                self._save()
                return updated
        return None

    def _save(self) -> None:
        self._data_path.parent.mkdir(parents=True, exist_ok=True)
        temporary_path = self._data_path.with_suffix(".tmp")
        temporary_path.write_text(
            json.dumps(
                [
                    item.model_dump(mode="json", exclude_none=True)
                    for item in self._items
                ],
                ensure_ascii=False,
                indent=2,
            ),
            encoding="utf-8",
        )
        temporary_path.replace(self._data_path)
