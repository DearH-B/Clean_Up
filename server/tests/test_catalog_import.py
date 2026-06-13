import shutil
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory

from app.catalog_import import CatalogImportError, import_catalog, write_outputs


class CatalogImportTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.template_dir = Path(__file__).resolve().parents[2] / "catalog_input"

    def test_unpublished_template_does_not_create_public_products(self) -> None:
        result = import_catalog(self.template_dir)

        self.assertEqual(result.products, [])
        self.assertEqual(result.models, [])

    def test_published_rows_generate_server_and_dart_outputs(self) -> None:
        with TemporaryDirectory() as directory:
            source = Path(directory) / "input"
            shutil.copytree(self.template_dir, source)
            self._publish_first_row(source / "products.csv")
            self._publish_first_row(source / "models.csv")

            result = import_catalog(source)

            self.assertEqual(result.products[0]["id"], "example-product-id")
            self.assertEqual(result.models[0]["modelName"], "MODEL-001")
            server_products = Path(directory) / "products.json"
            server_models = Path(directory) / "models.json"
            dart_output = Path(directory) / "generated.dart"
            write_outputs(
                result,
                server_products=server_products,
                server_models=server_models,
                dart_output=dart_output,
            )
            self.assertIn("example-product-id", server_products.read_text("utf-8"))
            dart = dart_output.read_text("utf-8")
            self.assertIn("generatedProductCatalogJson", dart)
            self.assertIn("MODEL-001", dart)

    def test_unknown_source_reference_is_rejected(self) -> None:
        with TemporaryDirectory() as directory:
            source = Path(directory) / "input"
            shutil.copytree(self.template_dir, source)
            self._publish_first_row(source / "products.csv")
            steps = (source / "steps.csv").read_text(encoding="utf-8")
            (source / "steps.csv").write_text(
                steps.replace("example-product-id-manual", "missing-source"),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(CatalogImportError, "등록되지 않은 출처"):
                import_catalog(source)

    @staticmethod
    def _publish_first_row(path: Path) -> None:
        content = path.read_text(encoding="utf-8")
        path.write_text(content.replace("\nfalse,", "\ntrue,", 1), encoding="utf-8")


if __name__ == "__main__":
    unittest.main()
