import json
from pathlib import Path

from .schemas import ProductDiagnostic, ReviewStatus, SourceType


class ProductDiagnosticCatalog:
    def __init__(self, data_path: Path) -> None:
        raw = json.loads(data_path.read_text(encoding="utf-8"))
        self.version = str(raw["version"])
        defaults = raw.get("defaults", {})
        source_registry = {
            source["id"]: source for source in raw.get("sources", [])
        }
        self._items: list[ProductDiagnostic] = []
        for group in raw["groups"]:
            product_types = group["productTypes"]
            group_defaults = group.get("defaults", {})
            for diagnostic in group["diagnostics"]:
                payload = {
                    **defaults,
                    **group_defaults,
                    **diagnostic,
                    "productTypes": product_types,
                }
                source_ids = payload.get("evidenceSourceIds", [])
                missing_source_ids = set(source_ids).difference(source_registry)
                if missing_source_ids:
                    diagnostic_id = payload.get("id", "unknown")
                    raise ValueError(
                        f"{diagnostic_id} references unknown diagnostic sources: "
                        f"{', '.join(sorted(missing_source_ids))}"
                    )
                payload["sources"] = [
                    source_registry[source_id] for source_id in source_ids
                ]
                item = ProductDiagnostic.model_validate(payload)
                self._validate_evidence(item, source_registry)
                self._items.append(item)

    @staticmethod
    def _validate_evidence(
        item: ProductDiagnostic,
        source_registry: dict[str, dict],
    ) -> None:
        referenced_ids = {
            *item.evidenceSourceIds,
            *(
                source_id
                for source_ids in item.stepSourceIds.values()
                for source_id in source_ids
            ),
        }
        missing = referenced_ids.difference(source_registry)
        if missing:
            raise ValueError(
                f"{item.id} references unknown diagnostic sources: "
                f"{', '.join(sorted(missing))}"
            )
        if item.reviewStatus != ReviewStatus.verified:
            if item.reviewStatus == ReviewStatus.reviewed and not item.sources:
                raise ValueError(
                    f"{item.id} cannot be reviewed without evidence sources"
                )
            return
        official_manual_ids = {
            source.id
            for source in item.sources
            if source.isOfficial and source.type == SourceType.officialManual
        }
        if not official_manual_ids:
            raise ValueError(
                f"{item.id} cannot be verified without an official manual"
            )
        if not item.reviewHistory or (
            item.reviewHistory[-1].status != ReviewStatus.verified
        ):
            raise ValueError(
                f"{item.id} verified status requires matching review history"
            )
        if item.steps:
            wildcard_ids = set(item.stepSourceIds.get("*", []))
            if not wildcard_ids.intersection(official_manual_ids):
                raise ValueError(
                    f"{item.id} steps require official manual evidence"
                )

    def for_product_type(self, product_type: str) -> list[ProductDiagnostic]:
        target = _normalize(product_type)
        return [
            item
            for item in self._items
            if any(
                target == _normalize(candidate)
                or target in _normalize(candidate)
                or _normalize(candidate) in target
                for candidate in item.productTypes
            )
        ]


def _normalize(value: str) -> str:
    return "".join(
        character.lower()
        for character in value
        if not character.isspace() and character not in "-_"
    )
