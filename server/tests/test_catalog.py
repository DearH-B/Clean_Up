import json
import os
import unittest
from datetime import UTC, date, datetime
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch

from fastapi.testclient import TestClient

from app import main as api_main
from app.catalog import ProductCatalog
from app.catalog_store import CatalogStore, CatalogWorkflowError
from app.diagnostics import ProductDiagnosticCatalog
from app.release_validation import ReleaseValidator, render_markdown
from app.schemas import (
    ReviewRecord,
    ReviewStatus,
    SubmissionCreate,
    SubmissionStatus,
    SubmissionType,
)
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

    def test_searches_model_name_with_small_typo(self) -> None:
        results = self.catalog.search("DCS-HM4AG-X")
        self.assertEqual(results[0].modelName, "DCS-HM4AG-W")

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

        self.assertTrue(
            {"RM70F63R2A", "RM80F91H1W", "RM70F90M1ZD"}.issubset(
                {item.modelName for item in results}
            )
        )
        target_models = {
            item.modelName: item
            for item in results
            if item.modelName in {"RM70F63R2A", "RM80F91H1W", "RM70F90M1ZD"}
        }
        self.assertTrue(
            all(item.releaseYear == 2025 for item in target_models.values())
        )
        self.assertTrue(all(item.imageUrl for item in target_models.values()))
        self.assertTrue(all(item.features for item in target_models.values()))

    def test_lists_verified_washer_models_with_images(self) -> None:
        results = self.catalog.models(category="세탁기", brand="삼성전자")

        self.assertTrue(
            {"WF25CB8895BW", "WF25DG8650BW", "WF25DG8250BW"}.issubset(
                {item.modelName for item in results}
            )
        )
        self.assertTrue(all(item.imageUrl for item in results))
        for model in {item.modelName for item in results}:
            product = self.catalog.search(model)[0]
            self.assertEqual(product.reviewStatus.value, "verified")
            self.assertIn("downloadcenter.samsung.com", product.officialManualUrl)
            self.assertIn("배수필터", " ".join(product.steps))
            self.assertIn("무세제통세척", " ".join(product.steps))

    def test_lists_verified_lg_models_with_official_manuals(
        self,
    ) -> None:
        expected = {
            "M875GBB231",
            "RG19GN",
            "AS355NSNA",
            "FX25EFE",
            "DUE4BGL1E",
        }
        for model_name in expected:
            product = self.catalog.search(model_name)[0]
            self.assertEqual(product.brand, "LG전자")
            self.assertEqual(product.reviewStatus, ReviewStatus.verified)
            self.assertEqual(product.matchLevelLabel, "공식 설명서 확인 모델")
            self.assertIn("gscs-manual.lge.com", product.officialManualUrl)
            self.assertTrue(product.imageUrl)

        pending = self.catalog.search("FQ18GV6EE1")[0]
        self.assertEqual(pending.reviewStatus, ReviewStatus.reviewed)
        self.assertIsNone(pending.officialManualUrl)

    def test_filters_model_search(self) -> None:
        results = self.catalog.models(
            category="TV",
            brand="삼성전자",
            query="QNF70",
        )

        self.assertEqual([item.modelName for item in results], ["KQ65QNF70AFXKR"])


class ProductDiagnosticCatalogTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        data_path = (
            Path(__file__).resolve().parents[1]
            / "data"
            / "product_diagnostics.json"
        )
        cls.diagnostics = ProductDiagnosticCatalog(data_path)

    def test_returns_safety_draft_washbasin_guides(self) -> None:
        results = self.diagnostics.for_product_type("세면대")

        self.assertEqual(len(results), 4)
        self.assertEqual(results[0].reviewStatus, ReviewStatus.draft)
        self.assertTrue(any(item.steps for item in results))
        self.assertTrue(any(item.tools for item in results))
        self.assertTrue(any(item.recommendedProducts for item in results))

    def test_unknown_product_type_is_left_to_client_fallback(self) -> None:
        self.assertEqual(self.diagnostics.for_product_type("등록 전 제품"), [])

    def test_release_product_groups_have_distinct_reviewed_guides(self) -> None:
        expected_ids = {
            "냉장고": {
                "refrigerator-power",
                "refrigerator-water",
                "refrigerator-door",
                "refrigerator-odor",
            },
            "세탁기": {
                "washer-leak",
                "washer-drain",
                "washer-noise",
                "washer-odor",
            },
            "식기세척기": {
                "dishwasher-leak",
                "dishwasher-drain",
                "dishwasher-cleaning",
                "dishwasher-odor",
            },
        }

        for product_type, identifiers in expected_ids.items():
            results = self.diagnostics.for_product_type(product_type)
            self.assertEqual({item.id for item in results}, identifiers)
            self.assertTrue(
                all(item.reviewStatus == ReviewStatus.verified for item in results)
            )
            self.assertTrue(any(item.warningSigns for item in results))
            self.assertTrue(any(item.steps and item.tools for item in results))

    def test_kimchi_refrigerator_uses_refrigerator_safety_guides(self) -> None:
        refrigerator_ids = {
            item.id for item in self.diagnostics.for_product_type("냉장고")
        }
        kimchi_refrigerator_ids = {
            item.id for item in self.diagnostics.for_product_type("김치냉장고")
        }

        self.assertEqual(kimchi_refrigerator_ids, refrigerator_ids)

    def test_all_standard_product_types_are_served_by_published_data(self) -> None:
        product_types = [
            "냉장고",
            "음식물처리기",
            "전자레인지",
            "식기세척기",
            "정수기",
            "싱크대",
            "TV",
            "소파",
            "테이블",
            "가습기",
            "공기청정기",
            "에어컨",
            "침대",
            "러그",
            "세면대",
            "변기",
            "샤워부스",
            "욕조",
            "환풍기",
            "욕실장",
            "매트리스",
            "옷장",
            "화장대",
            "세탁기",
            "건조기",
            "세탁조",
            "빨래건조대",
            "책상",
            "의자",
            "모니터",
            "컴퓨터",
            "책장",
            "신발장",
            "현관문",
            "중문",
            "현관 매트",
            "창문",
            "방충망",
            "실외기",
            "수납장",
            "김치냉장고",
            "인덕션",
            "가스레인지",
            "오븐",
            "커피머신",
            "전기밥솥",
            "믹서기",
            "토스터",
            "제습기",
            "선풍기",
            "로봇청소기",
            "청소기",
            "스피커",
            "프로젝터",
            "게임기",
            "공유기",
            "프린터",
            "안마의자",
            "전기장판",
            "협탁",
            "식탁",
            "서랍장",
            "커튼",
            "블라인드",
            "거울",
        ]

        for product_type in product_types:
            results = self.diagnostics.for_product_type(product_type)
            self.assertGreaterEqual(
                len(results),
                3,
                f"{product_type} does not have enough diagnostics",
            )
            self.assertTrue(
                all(
                    item.reviewStatus in {ReviewStatus.draft, ReviewStatus.verified}
                    for item in results
                ),
                f"{product_type} includes an unsupported review state",
            )
            self.assertFalse(
                any(item.id.startswith("generic-") for item in results),
                f"{product_type} uses a generic diagnostic",
            )
            self.assertTrue(
                any(item.steps and item.tools for item in results),
                f"{product_type} has no actionable guide",
            )
            self.assertTrue(
                any(item.requires_stop for item in results),
                f"{product_type} has no stop or support outcome",
            )

    def test_verified_guides_have_official_manual_step_evidence(self) -> None:
        for product_type in ["냉장고", "세탁기", "식기세척기"]:
            for item in self.diagnostics.for_product_type(product_type):
                manual_ids = {
                    source.id
                    for source in item.sources
                    if source.isOfficial and source.type.value == "officialManual"
                }
                self.assertTrue(manual_ids)
                self.assertEqual(item.reviewHistory[-1].status, ReviewStatus.verified)
                if item.steps:
                    self.assertTrue(
                        manual_ids.intersection(item.stepSourceIds.get("*", []))
                    )

    def test_rejects_verified_guide_without_official_manual(self) -> None:
        payload = {
            "version": "test",
            "defaults": {
                "reviewedAt": "2026-06-15",
                "applicableMaterials": ["설명서 확인"],
            },
            "sources": [],
            "groups": [
                {
                    "productTypes": ["테스트제품"],
                    "diagnostics": [
                        {
                            "id": "invalid-verified",
                            "symptom": "이상",
                            "question": "확인했나요?",
                            "safeAction": "사용을 멈추세요.",
                            "outcome": "stopUsing",
                            "reviewStatus": "verified",
                            "basisType": "manufacturerGuide",
                            "reviewHistory": [
                                {
                                    "status": "verified",
                                    "reviewer": "test",
                                    "reviewedAt": "2026-06-15",
                                    "note": "invalid",
                                }
                            ],
                        }
                    ],
                }
            ],
        }
        with TemporaryDirectory() as directory:
            path = Path(directory) / "diagnostics.json"
            path.write_text(
                json.dumps(payload, ensure_ascii=False),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "official manual"):
                ProductDiagnosticCatalog(path)

    def test_rejects_reviewed_guide_without_evidence_source(self) -> None:
        payload = {
            "version": "test",
            "defaults": {
                "reviewedAt": "2026-06-15",
                "applicableMaterials": ["설명서 확인"],
            },
            "sources": [],
            "groups": [
                {
                    "productTypes": ["테스트제품"],
                    "diagnostics": [
                        {
                            "id": "invalid-reviewed",
                            "symptom": "이상",
                            "question": "확인했나요?",
                            "safeAction": "사용을 멈추세요.",
                            "outcome": "stopUsing",
                            "reviewStatus": "reviewed",
                        }
                    ],
                }
            ],
        }
        with TemporaryDirectory() as directory:
            path = Path(directory) / "diagnostics.json"
            path.write_text(
                json.dumps(payload, ensure_ascii=False),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "without evidence sources"):
                ProductDiagnosticCatalog(path)


class CatalogStoreTest(unittest.TestCase):
    def test_draft_review_verify_workflow_and_audit_log(self) -> None:
        source_path = Path(__file__).resolve().parents[1] / "data" / "products.json"
        source_product = ProductCatalog(source_path).search("DCS-HM4AG-W")[0]
        draft = source_product.model_copy(
            update={
                "id": "workflow-test-product",
                "reviewStatus": ReviewStatus.draft,
                "reviewHistory": [
                    ReviewRecord(
                        status=ReviewStatus.draft,
                        reviewer="author",
                        reviewedAt=date.today(),
                        note="initial draft",
                    )
                ],
            }
        )
        with TemporaryDirectory() as directory:
            store = CatalogStore(Path(directory) / "catalog.db")
            store.upsert(draft, operator="author", note="create")
            reviewed = store.transition(
                draft.id,
                target=ReviewStatus.reviewed,
                operator="reviewer",
                note="source checked",
            )
            verified = store.transition(
                draft.id,
                target=ReviewStatus.verified,
                operator="verifier",
                note="release approved",
            )

            self.assertEqual(reviewed.reviewStatus, ReviewStatus.reviewed)
            self.assertEqual(verified.reviewStatus, ReviewStatus.verified)
            self.assertEqual(store.published()[0].id, draft.id)
            self.assertEqual(len(store.audit_log(draft.id)), 3)
            with self.assertRaises(CatalogWorkflowError):
                store.upsert(verified, operator="author", note="edit")

    def test_creates_consistent_sqlite_backup(self) -> None:
        with TemporaryDirectory() as directory:
            database_path = Path(directory) / "catalog.db"
            backup_path = Path(directory) / "backup" / "catalog.db"
            store = CatalogStore(database_path)

            store.backup_to(backup_path)

            self.assertTrue(backup_path.exists())
            self.assertEqual(CatalogStore(backup_path).list(), [])

    def test_restores_backup_into_separate_database_and_verifies_integrity(
        self,
    ) -> None:
        with TemporaryDirectory() as directory:
            root = Path(directory)
            database_path = root / "catalog.db"
            backup_path = root / "backup" / "catalog.db"
            restored_path = root / "restored" / "catalog.db"
            store = CatalogStore(database_path)

            store.backup_to(backup_path)
            report = store.restore_drill(backup_path, restored_path)

            self.assertEqual(report["integrity"], "ok")
            self.assertEqual(report["products"], 0)
            self.assertEqual(report["auditEvents"], 0)
            self.assertTrue(restored_path.exists())

    def test_restore_drill_refuses_to_overwrite_existing_database(self) -> None:
        with TemporaryDirectory() as directory:
            root = Path(directory)
            store = CatalogStore(root / "catalog.db")
            backup_path = root / "backup.db"
            restored_path = root / "restored.db"
            store.backup_to(backup_path)
            restored_path.touch()

            with self.assertRaises(CatalogWorkflowError):
                store.restore_drill(backup_path, restored_path)


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
        self.assertEqual(washer_decisions["WF25DG8650BW"], "approved")
        self.assertEqual(washer_decisions["WF25DG8250BW"], "approved")

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

    def test_accepts_app_issue_with_screen_context(self) -> None:
        with TemporaryDirectory() as directory:
            store = SubmissionStore(Path(directory) / "submissions.json")
            payload = SubmissionCreate(
                clientSubmissionId="app-issue-1",
                type=SubmissionType.appIssue,
                title="저장 버튼이 동작하지 않음",
                details="제품 메모를 입력하고 저장을 눌렀지만 반영되지 않았어요.",
                screenContext="제품 상세 · 주방",
                createdAt=datetime.now(UTC),
            )

            created = store.create(payload)

            self.assertEqual(created.type, SubmissionType.appIssue)
            self.assertEqual(created.screenContext, "제품 상세 · 주방")


class AdminSubmissionApiTest(unittest.TestCase):
    def test_admin_submission_api_requires_configured_key(self) -> None:
        client = TestClient(api_main.app)

        with patch.dict(os.environ, {"CATALOG_ADMIN_API_KEY": ""}, clear=False):
            response = client.get("/v1/admin/submissions")

        self.assertEqual(response.status_code, 503)

    def test_admin_can_list_and_update_submission_status(self) -> None:
        with TemporaryDirectory() as directory:
            store = SubmissionStore(Path(directory) / "submissions.json")
            created = store.create(
                SubmissionCreate(
                    clientSubmissionId="admin-request-1",
                    type=SubmissionType.missingProduct,
                    title="없는 제품",
                    details="모델 정보 요청",
                    createdAt=datetime.now(UTC),
                )
            )
            client = TestClient(api_main.app)
            headers = {"X-Admin-Key": "test-secret"}

            with (
                patch.object(api_main, "submissions", store),
                patch.dict(
                    os.environ,
                    {"CATALOG_ADMIN_API_KEY": "test-secret"},
                    clear=False,
                ),
            ):
                list_response = client.get(
                    "/v1/admin/submissions",
                    headers=headers,
                )
                update_response = client.post(
                    f"/v1/admin/submissions/{created.trackingToken}/status",
                    headers=headers,
                    json={
                        "status": "investigating",
                        "operator": "reviewer@example.com",
                        "note": "공식 자료 확인 중",
                    },
                )

        self.assertEqual(list_response.status_code, 200)
        self.assertEqual(len(list_response.json()), 1)
        self.assertEqual(update_response.status_code, 200)
        self.assertEqual(update_response.json()["status"], "investigating")
        self.assertEqual(len(update_response.json()["reviewHistory"]), 2)


if __name__ == "__main__":
    unittest.main()
