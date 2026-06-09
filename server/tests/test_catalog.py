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

    def test_products_have_sources_and_matching_review_history(self) -> None:
        results = self.catalog.search("")
        self.assertTrue(all(item.sources for item in results))
        self.assertTrue(all(item.reviewHistory for item in results))
        self.assertTrue(
            all(item.reviewHistory[-1].status == item.reviewStatus for item in results)
        )

    def test_source_references_point_to_existing_sources(self) -> None:
        for product in self.catalog.search(""):
            source_ids = {source.id for source in product.sources}
            references = [
                *product.specSourceIds.values(),
                *product.stepSourceIds.values(),
            ]
            self.assertTrue(
                all(source_id in source_ids for group in references for source_id in group)
            )


if __name__ == "__main__":
    unittest.main()
