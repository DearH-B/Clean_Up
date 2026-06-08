import json
import re
from pathlib import Path

from .schemas import CatalogProduct, ReviewStatus


class ProductCatalog:
    def __init__(self, data_path: Path) -> None:
        self._data_path = data_path
        self._products = self._load()

    def _load(self) -> list[CatalogProduct]:
        raw_items = json.loads(self._data_path.read_text(encoding="utf-8"))
        return [CatalogProduct.model_validate(item) for item in raw_items]

    def reload(self) -> None:
        self._products = self._load()

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


def _search_text(product: CatalogProduct) -> str:
    values = [
        product.name,
        product.categoryName,
        product.brand,
        product.manufacturer,
        product.modelName,
        product.productMethod,
        *product.keywords,
    ]
    return " ".join(_normalize(value) for value in values)


def _normalize(value: str) -> str:
    return re.sub(r"[\s\-_]+", "", value.lower())
