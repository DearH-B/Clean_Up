import unittest
from pathlib import Path

from app.catalog import ProductCatalog


class ProductCatalogTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        data_path = Path(__file__).resolve().parents[1] / "data" / "products.json"
        cls.catalog = ProductCatalog(data_path)

    def test_searches_by_model_name(self) -> None:
        results = self.catalog.search("DCS-HM4AG-W")
        self.assertEqual(results[0].id, "eco-up-dcs-hm4ag-w")

    def test_searches_by_alias(self) -> None:
        results = self.catalog.search("음처기")
        self.assertEqual(results[0].brand, "에코업")

    def test_category_filter_accepts_product_name(self) -> None:
        results = self.catalog.search("DCS", category="에코업 음식물처리기")
        self.assertEqual(results[0].modelName, "DCS-HM4AG-W")

    def test_returns_reviewed_products_only(self) -> None:
        results = self.catalog.search("")
        self.assertTrue(results)
        self.assertTrue(
            all(item.reviewStatus.value in {"reviewed", "verified"} for item in results)
        )


if __name__ == "__main__":
    unittest.main()
