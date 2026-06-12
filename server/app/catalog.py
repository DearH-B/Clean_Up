import json
import re
from pathlib import Path

from .representative_catalog import representative_products
from .schemas import CatalogModelOption, CatalogProduct, ReviewStatus


class ProductCatalog:
    def __init__(self, data_path: Path) -> None:
        self._data_path = data_path
        self._models_path = data_path.with_name("models.json")
        self._products = self._load()
        self._models = self._load_models()

    def _load(self) -> list[CatalogProduct]:
        raw_items = [
            *json.loads(self._data_path.read_text(encoding="utf-8")),
            *representative_products(),
        ]
        products = [CatalogProduct.model_validate(item) for item in raw_items]
        for product in products:
            _validate_source_references(product)
        return products

    def reload(self) -> None:
        self._products = self._load()
        self._models = self._load_models()

    def _load_models(self) -> list[CatalogModelOption]:
        if not self._models_path.exists():
            return []
        raw_items = json.loads(self._models_path.read_text(encoding="utf-8"))
        return [CatalogModelOption.model_validate(item) for item in raw_items]

    def search(
        self,
        query: str = "",
        *,
        category: str | None = None,
        brand: str | None = None,
        include_reviewed: bool = True,
    ) -> list[CatalogProduct]:
        normalized_query = _normalize(query)
        allowed_statuses = {ReviewStatus.verified}
        if include_reviewed:
            allowed_statuses.add(ReviewStatus.reviewed)

        results = []
        for product in self._products:
            if product.reviewStatus not in allowed_statuses:
                continue
            if category:
                product_category = _normalize(product.categoryName)
                requested_category = _normalize(category)
                if (
                    product_category not in requested_category
                    and requested_category not in product_category
                ):
                    continue
            if brand and _normalize(product.brand) != _normalize(brand):
                continue
            if normalized_query and normalized_query not in _search_text(product):
                continue
            results.append(product)
        return results

    def get(self, product_id: str) -> CatalogProduct | None:
        return next(
            (
                product
                for product in self._products
                if product.id == product_id
                and product.reviewStatus in {ReviewStatus.reviewed, ReviewStatus.verified}
            ),
            None,
        )

    def brands(self, category: str) -> list[str]:
        normalized_category = _normalize(category)
        brands = {
            model.brand
            for model in self._models
            if _normalize(model.categoryName) == normalized_category
            and model.reviewStatus in {ReviewStatus.reviewed, ReviewStatus.verified}
        }
        brands.update(
            product.brand
            for product in self._products
            if _normalize(product.categoryName) == normalized_category
            and product.brand != "브랜드 미상"
            and product.reviewStatus in {ReviewStatus.reviewed, ReviewStatus.verified}
        )
        return sorted(brands)

    def models(
        self,
        *,
        category: str,
        brand: str,
        query: str = "",
    ) -> list[CatalogModelOption]:
        normalized_category = _normalize(category)
        normalized_brand = _normalize(brand)
        normalized_query = _normalize(query)
        results = [
            model
            for model in self._models
            if _normalize(model.categoryName) == normalized_category
            and _normalize(model.brand) == normalized_brand
            and model.reviewStatus in {ReviewStatus.reviewed, ReviewStatus.verified}
            and (
                not normalized_query
                or normalized_query in _normalize(model.modelName)
                or normalized_query in _normalize(model.displayName)
            )
        ]
        return sorted(
            results,
            key=lambda item: (item.releaseYear or 0, item.modelName),
            reverse=True,
        )


def _search_text(product: CatalogProduct) -> str:
    values = [
        product.name,
        product.categoryName,
        product.brand,
        product.manufacturer,
        product.seriesName,
        product.modelName,
        product.productMethod,
        *product.keywords,
    ]
    return " ".join(_normalize(value) for value in values)


def _normalize(value: str) -> str:
    return re.sub(r"[\s\-_]+", "", value.lower())


def _validate_source_references(product: CatalogProduct) -> None:
    source_ids = {source.id for source in product.sources}
    referenced_ids = {
        source_id
        for references in [
            *product.specSourceIds.values(),
            *product.stepSourceIds.values(),
        ]
        for source_id in references
    }
    missing_ids = referenced_ids - source_ids
    if missing_ids:
        missing = ", ".join(sorted(missing_ids))
        raise ValueError(f"{product.id} references unknown sources: {missing}")

    if product.reviewHistory[-1].status != product.reviewStatus:
        raise ValueError(
            f"{product.id} review history does not match reviewStatus"
        )

    for spec in product.productSpecs:
        if not re.search(r"\d", spec):
            continue
        label = spec.split(":", maxsplit=1)[0].strip()
        if not product.specSourceIds.get(label):
            raise ValueError(
                f"{product.id} numeric spec has no source: {label}"
            )
