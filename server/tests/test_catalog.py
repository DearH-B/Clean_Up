import unittest
from datetime import UTC, date, datetime
from pathlib import Path
from tempfile import TemporaryDirectory

from app.catalog import ProductCatalog
from app.release_validation import ReleaseValidator, render_markdown
from app.schemas import SubmissionCreate, SubmissionStatus, SubmissionType
from app.submissions import SubmissionStore


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

    def test_unconfirmed_schedule_is_not_published_as_a_number(self) -> None:
        product = self.catalog.search("DCS-HM4AG-W")[0]

        self.assertEqual(product.recurrenceDays, 0)
        self.assertEqual(product.estimatedMinutes, 0)
        self.assertEqual(product.reviewStatus.value, "reviewed")
        self.assertIn("공식 관리 주기 미확인", product.frequency)

    def test_contains_five_completed_series(self) -> None:
        expected_ids = {
            "samsung-bespoke-ai-refrigerator-4door",
            "lg-dios-objet-refrigerator-top-bottom",
            "samsung-bespoke-ai-washer",
            "lg-tromm-objet-drum-washer",
            "samsung-bespoke-ai-windfree-classic",
        }
        actual_ids = {product.id for product in self.catalog.search("")}

        self.assertTrue(expected_ids.issubset(actual_ids))
        self.assertEqual(
            self.catalog.search("트롬 오브제컬렉션")[0].seriesName,
            "트롬 오브제컬렉션 드럼세탁기",
        )
        self.assertEqual(
            self.catalog.search("무풍클래식")[0].matchLevelLabel,
            "시리즈 기준",
        )

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

    def test_lists_brands_by_category(self) -> None:
        self.assertIn("삼성전자", self.catalog.brands("TV"))
        self.assertIn("삼성전자", self.catalog.brands("냉장고"))

    def test_lists_verified_models_by_brand(self) -> None:
        results = self.catalog.models(category="TV", brand="삼성전자")

        self.assertEqual(results[0].releaseYear, 2025)
        self.assertIn("KQ65QNF90AFXKR", {item.modelName for item in results})

    def test_lists_verified_refrigerator_models_with_images(self) -> None:
        results = self.catalog.models(category="냉장고", brand="삼성전자")

        self.assertEqual(
            {item.modelName for item in results},
            {"RM70F63R2A", "RM80F91H1W", "RM70F90M1ZD"},
        )
        self.assertTrue(all(item.releaseYear == 2025 for item in results))
        self.assertTrue(all(item.imageUrl for item in results))
        self.assertTrue(all(item.features for item in results))

    def test_lists_verified_washer_models_with_images(self) -> None:
        results = self.catalog.models(category="세탁기", brand="삼성전자")

        self.assertEqual(
            {item.modelName for item in results},
            {"WF25CB8895BW", "WF25DG8650BW", "WF25DG8250BW"},
        )
        self.assertTrue(all(item.imageUrl for item in results))
        for model in {item.modelName for item in results}:
            product = self.catalog.search(model)[0]
            self.assertEqual(product.reviewStatus.value, "verified")
            self.assertIn("downloadcenter.samsung.com", product.officialManualUrl)
            self.assertIn("배수필터", " ".join(product.steps))
            self.assertIn("무세제통세척", " ".join(product.steps))

    def test_filters_model_search(self) -> None:
        results = self.catalog.models(
            category="TV",
            brand="삼성전자",
            query="QNF70",
        )

        self.assertEqual([item.modelName for item in results], ["KQ65QNF70AFXKR"])


class ReleaseValidatorTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        data_dir = Path(__file__).resolve().parents[1] / "data"
        cls.validator = ReleaseValidator(
            data_dir / "products.json",
            data_dir / "release_readiness.json",
            today=date(2026, 6, 13),
        )

    def test_validates_six_release_products_individually(self) -> None:
        report = self.validator.validate()

        self.assertEqual(
            {product.model_name for product in report.products},
            {
                "RM70F63R2A",
                "RM80F91H1W",
                "RM70F90M1ZD",
                "WF25CB8895BW",
                "WF25DG8650BW",
                "WF25DG8250BW",
            },
        )
        for product in report.products:
            automated = {
                check.check_id: check.status.value
                for check in product.checks
                if check.check_id
                in {
                    "catalog_verified",
                    "official_identity_source",
                    "official_manual_source",
                    "source_traceability",
                    "safety_guidance",
                    "model_specific_claims",
                    "support_information",
                    "source_freshness",
                }
            }
            self.assertTrue(automated)
            self.assertTrue(all(status == "passed" for status in automated.values()))

    def test_release_remains_blocked_until_manual_gates_pass(self) -> None:
        report = self.validator.validate()

        self.assertEqual(report.decision.value, "blocked")
        self.assertTrue(
            any(check.status.value == "blocked" for check in report.app_checks)
        )
        self.assertEqual(
            next(
                product
                for product in report.products
                if product.model_name == "RM70F63R2A"
            ).decision.value,
            "approved",
        )
        self.assertEqual(
            next(
                product
                for product in report.products
                if product.model_name == "RM80F91H1W"
            ).decision.value,
            "approved",
        )
        self.assertTrue(
            all(
                product.decision.value == "approved"
                for product in report.products
                if product.model_name.startswith("RM")
            )
        )
        washer_decisions = {
            product.model_name: product.decision.value
            for product in report.products
            if product.model_name.startswith("WF")
        }
        self.assertEqual(washer_decisions["WF25CB8895BW"], "approved")
        self.assertEqual(washer_decisions["WF25DG8650BW"], "blocked")
        self.assertEqual(washer_decisions["WF25DG8250BW"], "blocked")

    def test_markdown_report_names_blockers(self) -> None:
        markdown = render_markdown(self.validator.validate())

        self.assertIn("최종 판정: `blocked`", markdown)
        self.assertIn("`physical_android_device`", markdown)
        self.assertIn("RM70F63R2A", markdown)
        self.assertIn("RM80F91H1W", markdown)
        self.assertIn("RM70F90M1ZD", markdown)
        self.assertIn("WF25CB8895BW", markdown)


class SubmissionStoreTest(unittest.TestCase):
    def test_creates_and_reads_submission(self) -> None:
        with TemporaryDirectory() as directory:
            store = SubmissionStore(Path(directory) / "submissions.json")
            payload = SubmissionCreate(
                clientSubmissionId="request-1",
                type=SubmissionType.missingProduct,
                title="없는 모델 정보 요청",
                details="모델명 ABC-123",
                modelName="ABC-123",
                createdAt=datetime.now(UTC),
            )

            created = store.create(payload)
            loaded = store.get(created.trackingToken)

            self.assertEqual(created.status, SubmissionStatus.received)
            self.assertEqual(loaded, created)

    def test_repeated_client_id_is_idempotent(self) -> None:
        with TemporaryDirectory() as directory:
            store = SubmissionStore(Path(directory) / "submissions.json")
            payload = SubmissionCreate(
                clientSubmissionId="request-duplicate",
                type=SubmissionType.incorrectInfo,
                title="제품 정보 확인",
                details="출시 연도가 달라요.",
                createdAt=datetime.now(UTC),
            )

            first = store.create(payload)
            second = store.create(payload)

            self.assertEqual(first.trackingToken, second.trackingToken)

    def test_updates_status_with_review_history(self) -> None:
        with TemporaryDirectory() as directory:
            store = SubmissionStore(Path(directory) / "submissions.json")
            payload = SubmissionCreate(
                clientSubmissionId="request-status",
                type=SubmissionType.unsafeGuide,
                title="위험 안내 확인",
                details="전원을 분리하라는 안내가 없어요.",
                createdAt=datetime.now(UTC),
            )
            created = store.create(payload)

            updated = store.update_status(
                created.trackingToken,
                status=SubmissionStatus.investigating,
                operator="reviewer@example.com",
                note="공식 설명서 대조 중",
            )

            self.assertIsNotNone(updated)
            self.assertEqual(updated.status, SubmissionStatus.investigating)
            self.assertEqual(len(updated.reviewHistory), 2)
            self.assertEqual(
                updated.reviewHistory[-1].operator,
                "reviewer@example.com",
            )


if __name__ == "__main__":
    unittest.main()
