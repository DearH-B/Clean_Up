import json
from dataclasses import dataclass
from datetime import date
from pathlib import Path

from .catalog import ProductCatalog
from .schemas import (
    CatalogProduct,
    ProductReleaseProfile,
    ReleaseCheckStatus,
    ReleaseDecision,
    ReleaseEvidence,
    ReleaseReadinessData,
    SourceType,
)


PRODUCT_AUTOMATED_CHECKS = {
    "catalog_verified",
    "official_identity_source",
    "official_manual_source",
    "source_traceability",
    "safety_guidance",
    "model_specific_claims",
    "support_information",
    "source_freshness",
}

REQUIRED_APP_CHECKS = {
    "automated_regression",
    "android_emulator_flow",
    "saved_data_migration",
    "offline_behavior",
    "external_link_failure",
    "accessibility_large_text",
    "physical_android_device",
    "privacy_terms_disclaimer",
    "monitoring_and_recovery",
    "release_signing",
}


@dataclass(frozen=True)
class ReleaseCheckResult:
    check_id: str
    status: ReleaseCheckStatus
    detail: str


@dataclass(frozen=True)
class ProductReleaseResult:
    product_id: str
    model_name: str
    decision: ReleaseDecision
    checks: list[ReleaseCheckResult]


@dataclass(frozen=True)
class ReleaseReport:
    target_release: str
    generated_at: date
    decision: ReleaseDecision
    app_checks: list[ReleaseCheckResult]
    products: list[ProductReleaseResult]


class ReleaseValidator:
    def __init__(
        self,
        catalog_path: Path,
        readiness_path: Path,
        *,
        today: date | None = None,
        stale_days: int = 180,
    ) -> None:
        self._catalog = ProductCatalog(catalog_path)
        self._readiness = ReleaseReadinessData.model_validate_json(
            readiness_path.read_text(encoding="utf-8")
        )
        self._today = today or date.today()
        self._stale_days = stale_days

    def validate(self, product_ids: set[str] | None = None) -> ReleaseReport:
        profiles = {
            profile.productId: profile for profile in self._readiness.products
        }
        selected_ids = product_ids or set(profiles)
        app_checks = self._manual_results(
            self._readiness.app.evidence,
            REQUIRED_APP_CHECKS,
        )
        products = []
        for product_id in sorted(selected_ids):
            product = self._catalog.get(product_id)
            if product is None:
                products.append(
                    ProductReleaseResult(
                        product_id=product_id,
                        model_name="-",
                        decision=ReleaseDecision.blocked,
                        checks=[
                            ReleaseCheckResult(
                                "catalog_product",
                                ReleaseCheckStatus.failed,
                                "공개 카탈로그에서 제품을 찾지 못했습니다.",
                            )
                        ],
                    )
                )
                continue
            profile = profiles.get(product_id)
            manual_checks = (
                self._manual_results(profile.evidence, set())
                if profile is not None
                else [
                    ReleaseCheckResult(
                        "release_profile",
                        ReleaseCheckStatus.failed,
                        "제품 출시 검증 프로필이 없습니다.",
                    )
                ]
            )
            checks = [*self._automated_product_checks(product), *manual_checks]
            products.append(
                ProductReleaseResult(
                    product_id=product.id,
                    model_name=product.modelName,
                    decision=self._decision(checks),
                    checks=checks,
                )
            )

        all_checks = [*app_checks]
        for product in products:
            all_checks.extend(product.checks)
        return ReleaseReport(
            target_release=self._readiness.app.targetRelease,
            generated_at=self._today,
            decision=self._decision(all_checks),
            app_checks=app_checks,
            products=products,
        )

    def _automated_product_checks(
        self,
        product: CatalogProduct,
    ) -> list[ReleaseCheckResult]:
        official_product = [
            source
            for source in product.sources
            if source.type == SourceType.officialProduct
            and source.isOfficial
            and source.isActive
        ]
        official_manual = [
            source
            for source in product.sources
            if source.type == SourceType.officialManual
            and source.isOfficial
            and source.isActive
        ]
        source_ids = {source.id for source in product.sources}
        traced_specs = all(
            references and set(references).issubset(source_ids)
            for references in product.specSourceIds.values()
        )
        traced_steps = len(product.stepSourceIds) == len(product.steps) and all(
            set(references).issubset(source_ids)
            for references in product.stepSourceIds.values()
        )
        safety_terms = ("전원 플러그", "물을 직접", "분리하지")
        safety_guidance = all(
            any(term in caution for caution in product.cautions)
            for term in safety_terms
        )
        unverified_parts = any(
            consumable.partNumber is not None
            and not any(
                consumable.name in supported
                for source in official_product
                for supported in source.supports
            )
            for consumable in product.consumableDetails
        )
        sources_fresh = all(
            source.isActive
            and (self._today - source.checkedAt).days <= self._stale_days
            for source in product.sources
        )
        checks = [
            self._auto(
                "catalog_verified",
                product.reviewStatus.value == "verified",
                "카탈로그 검수 상태가 verified입니다.",
                "카탈로그 검수 상태가 verified가 아닙니다.",
            ),
            self._auto(
                "official_identity_source",
                bool(official_product)
                and bool(product.modelName)
                and bool(product.imageUrl)
                and product.releaseYear is not None,
                "공식 제품 페이지로 모델명, 이미지와 출시 연도를 추적합니다.",
                "공식 제품 식별 근거가 부족합니다.",
            ),
            self._auto(
                "official_manual_source",
                bool(official_manual)
                and bool(product.officialManualUrl)
                and any(
                    source.url == product.officialManualUrl
                    for source in official_manual
                ),
                "공식 설명서 원문과 앱 링크가 일치합니다.",
                "공식 설명서 원문 또는 앱 링크가 누락됐습니다.",
            ),
            self._auto(
                "source_traceability",
                traced_specs and traced_steps,
                "모든 스펙과 관리 단계가 등록된 출처를 참조합니다.",
                "출처가 연결되지 않은 스펙 또는 관리 단계가 있습니다.",
            ),
            self._auto(
                "safety_guidance",
                safety_guidance,
                "전원 차단, 직접 물 분사 금지와 임의 분해 금지를 포함합니다.",
                "필수 안전 안내가 부족합니다.",
            ),
            self._auto(
                "model_specific_claims",
                not unverified_parts,
                "공식 근거 없는 부품번호를 노출하지 않습니다.",
                "공식 근거가 없는 부품번호가 있습니다.",
            ),
            self._auto(
                "support_information",
                bool(product.supportUrl) and bool(product.servicePhone),
                "공식 지원 링크와 서비스센터 연락처가 있습니다.",
                "지원 링크 또는 서비스센터 연락처가 없습니다.",
            ),
            self._auto(
                "source_freshness",
                sources_fresh,
                f"모든 출처가 {self._stale_days}일 이내에 확인됐습니다.",
                f"{self._stale_days}일을 넘었거나 비활성인 출처가 있습니다.",
            ),
        ]
        assert {check.check_id for check in checks} == PRODUCT_AUTOMATED_CHECKS
        return checks

    def _manual_results(
        self,
        evidence: list[ReleaseEvidence],
        required_ids: set[str],
    ) -> list[ReleaseCheckResult]:
        evidence_by_id = {item.checkId: item for item in evidence}
        results = [
            ReleaseCheckResult(
                check_id=item.checkId,
                status=item.status,
                detail=(
                    f"{item.evidence}"
                    + (f" ({item.note})" if item.note else "")
                    + f" [{item.verifier}, {item.verifiedAt.isoformat()}]"
                ),
            )
            for item in evidence
        ]
        for missing_id in sorted(required_ids - set(evidence_by_id)):
            results.append(
                ReleaseCheckResult(
                    missing_id,
                    ReleaseCheckStatus.failed,
                    "필수 출시 증거가 등록되지 않았습니다.",
                )
            )
        return sorted(results, key=lambda item: item.check_id)

    def _auto(
        self,
        check_id: str,
        passed: bool,
        success: str,
        failure: str,
    ) -> ReleaseCheckResult:
        return ReleaseCheckResult(
            check_id,
            ReleaseCheckStatus.passed if passed else ReleaseCheckStatus.failed,
            success if passed else failure,
        )

    @staticmethod
    def _decision(checks: list[ReleaseCheckResult]) -> ReleaseDecision:
        blocking = {
            ReleaseCheckStatus.failed,
            ReleaseCheckStatus.blocked,
        }
        return (
            ReleaseDecision.blocked
            if any(check.status in blocking for check in checks)
            else ReleaseDecision.approved
        )


def render_markdown(report: ReleaseReport) -> str:
    labels = {
        ReleaseCheckStatus.passed: "PASS",
        ReleaseCheckStatus.failed: "FAIL",
        ReleaseCheckStatus.blocked: "BLOCKED",
        ReleaseCheckStatus.notApplicable: "N/A",
    }
    lines = [
        "# 제품 출시 검증 보고서",
        "",
        f"- 대상 릴리스: `{report.target_release}`",
        f"- 생성일: {report.generated_at.isoformat()}",
        f"- 최종 판정: `{report.decision.value}`",
        "",
        "## 앱 공통 검사",
        "",
    ]
    for check in report.app_checks:
        lines.append(
            f"- [{labels[check.status]}] `{check.check_id}`: {check.detail}"
        )
    for product in report.products:
        lines.extend(
            [
                "",
                f"## {product.model_name}",
                "",
                f"판정: `{product.decision.value}`",
                "",
            ]
        )
        for check in product.checks:
            lines.append(
                f"- [{labels[check.status]}] `{check.check_id}`: {check.detail}"
            )
    lines.extend(
        [
            "",
            "## 판정 원칙",
            "",
            "- `FAIL` 또는 `BLOCKED`가 하나라도 있으면 출시 검증 완료로 표시하지 않는다.",
            "- 자동 검사는 카탈로그를 읽을 때마다 다시 계산한다.",
            "- 수동 검사는 검증일, 검증자와 재현 가능한 증거를 함께 남긴다.",
            "",
        ]
    )
    return "\n".join(lines)
