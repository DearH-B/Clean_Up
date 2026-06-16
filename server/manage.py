import argparse
from collections import Counter
from datetime import date
from pathlib import Path

from app.catalog import ProductCatalog
from app.catalog_import import CatalogImportError, import_catalog, write_outputs
from app.catalog_store import CatalogStore, CatalogWorkflowError
from app.release_validation import ReleaseValidator, render_markdown
from app.schemas import CatalogProduct, ReviewStatus, SubmissionStatus
from app.submissions import SubmissionStore


BASE_DIR = Path(__file__).resolve().parent
CATALOG_PATH = BASE_DIR / "data" / "products.json"
SUBMISSIONS_PATH = BASE_DIR / "data" / "submissions.json"
RELEASE_READINESS_PATH = BASE_DIR / "data" / "release_readiness.json"
CATALOG_DATABASE_PATH = BASE_DIR / "data" / "catalog_admin.db"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="제품 카탈로그 운영 도구")
    commands = parser.add_subparsers(dest="command", required=True)

    catalog = commands.add_parser("catalog", help="카탈로그 품질 보고서")
    catalog.add_argument(
        "--stale-days",
        type=int,
        default=180,
        help="재검수 대상으로 볼 출처 경과 일수",
    )

    release = commands.add_parser("release", help="실제 출시 준비 상태 검증")
    release.add_argument(
        "--product",
        action="append",
        dest="products",
        help="검증할 제품 ID. 여러 번 지정할 수 있음",
    )
    release.add_argument(
        "--output",
        type=Path,
        help="Markdown 보고서 저장 경로",
    )
    release.add_argument(
        "--allow-blocked",
        action="store_true",
        help="차단 항목이 있어도 종료 코드를 0으로 반환",
    )

    importer = commands.add_parser(
        "import-catalog",
        help="CSV 폴더 또는 Excel 파일을 검증하고 앱·서버 카탈로그 생성",
    )
    importer.add_argument(
        "source",
        nargs="?",
        type=Path,
        default=BASE_DIR.parent / "catalog_input",
        help="CSV 폴더 또는 .xlsx 파일 경로",
    )
    importer.add_argument(
        "--check",
        action="store_true",
        help="검증만 하고 파일은 생성하지 않음",
    )

    submissions = commands.add_parser("submissions", help="사용자 제보 관리")
    submission_commands = submissions.add_subparsers(
        dest="submission_command",
        required=True,
    )
    list_command = submission_commands.add_parser("list", help="제보 목록")
    list_command.add_argument(
        "--status",
        choices=[status.value for status in SubmissionStatus],
    )

    update_command = submission_commands.add_parser(
        "update",
        help="제보 상태 변경",
    )
    update_command.add_argument("tracking_token")
    update_command.add_argument(
        "status",
        choices=[status.value for status in SubmissionStatus],
    )
    update_command.add_argument("--operator", required=True)
    update_command.add_argument("--note", required=True)

    managed = commands.add_parser("managed-catalog", help="운영 카탈로그 관리")
    managed_commands = managed.add_subparsers(
        dest="managed_command",
        required=True,
    )
    managed_list = managed_commands.add_parser("list", help="운영 제품 목록")
    managed_list.add_argument(
        "--status",
        choices=[status.value for status in ReviewStatus],
    )
    managed_import = managed_commands.add_parser(
        "import",
        help="JSON 제품을 초안으로 등록 또는 수정",
    )
    managed_import.add_argument("source", type=Path)
    managed_import.add_argument("--operator", required=True)
    managed_import.add_argument("--note", required=True)
    managed_transition = managed_commands.add_parser(
        "transition",
        help="제품 검수 상태 변경",
    )
    managed_transition.add_argument("product_id")
    managed_transition.add_argument(
        "status",
        choices=[status.value for status in ReviewStatus],
    )
    managed_transition.add_argument("--operator", required=True)
    managed_transition.add_argument("--note", required=True)
    managed_audit = managed_commands.add_parser("audit", help="변경 이력")
    managed_audit.add_argument("--product")
    managed_audit.add_argument("--limit", type=int, default=100)
    managed_backup = managed_commands.add_parser(
        "backup",
        help="운영 카탈로그 SQLite 안전 백업",
    )
    managed_backup.add_argument("destination", type=Path)
    managed_restore = managed_commands.add_parser(
        "restore-drill",
        help="백업을 별도 위치에 복원하고 무결성과 데이터 수를 검증",
    )
    managed_restore.add_argument("backup", type=Path)
    managed_restore.add_argument("destination", type=Path)
    return parser


def catalog_report(stale_days: int) -> int:
    catalog = ProductCatalog(CATALOG_PATH)
    products = catalog.search("")
    category_counts = Counter(product.categoryName for product in products)
    status_counts = Counter(product.reviewStatus.value for product in products)
    stale_sources = [
        (product, source)
        for product in products
        for source in product.sources
        if not source.isActive
        or (date.today() - source.checkedAt).days > stale_days
    ]

    print(f"공개 카탈로그: {len(products)}개")
    print("검수 상태:")
    for status, count in sorted(status_counts.items()):
        print(f"  {status}: {count}")
    print("제품군:")
    for category, count in sorted(category_counts.items()):
        print(f"  {category}: {count}")
    print(f"재검수 대상 출처: {len(stale_sources)}개")
    for product, source in stale_sources:
        print(
            f"  {product.id} | {source.id} | "
            f"{source.checkedAt.isoformat()} | {source.title}"
        )
    remaining = max(0, 25 - len(products))
    print(f"Phase 2 목표까지 남은 검수 항목: {remaining}개")
    return 0


def list_submissions(status_value: str | None) -> int:
    store = SubmissionStore(SUBMISSIONS_PATH)
    status = SubmissionStatus(status_value) if status_value else None
    items = store.list(status)
    if not items:
        print("조건에 맞는 제보가 없습니다.")
        return 0
    for item in items:
        identity = " · ".join(
            value
            for value in [item.brand, item.modelName, item.productName]
            if value
        )
        print(
            f"{item.trackingToken} | {item.status.value} | "
            f"{item.type.value} | {item.title}"
        )
        if identity:
            print(f"  {identity}")
        print(f"  {item.updatedAt.isoformat()} | {item.statusMessage or '-'}")
    return 0


def update_submission(
    tracking_token: str,
    status_value: str,
    operator: str,
    note: str,
) -> int:
    store = SubmissionStore(SUBMISSIONS_PATH)
    updated = store.update_status(
        tracking_token,
        status=SubmissionStatus(status_value),
        operator=operator,
        note=note,
    )
    if updated is None:
        print("해당 추적 토큰의 제보를 찾지 못했습니다.")
        return 1
    print(
        f"{updated.trackingToken} -> {updated.status.value} "
        f"({updated.updatedAt.isoformat()})"
    )
    return 0


def release_report(
    product_ids: list[str] | None,
    output: Path | None,
    allow_blocked: bool,
) -> int:
    validator = ReleaseValidator(CATALOG_PATH, RELEASE_READINESS_PATH)
    report = validator.validate(set(product_ids) if product_ids else None)
    markdown = render_markdown(report)
    print(markdown)
    if output is not None:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(markdown, encoding="utf-8")
        print(f"\n보고서 저장: {output}")
    if report.decision.value == "blocked" and not allow_blocked:
        return 2
    return 0


def import_catalog_data(source: Path, check_only: bool) -> int:
    try:
        result = import_catalog(source.resolve())
    except (CatalogImportError, ValueError) as error:
        print(f"카탈로그 입력 오류: {error}")
        return 1

    print(f"검증 완료: 제품 {len(result.products)}개, 모델 후보 {len(result.models)}개")
    if check_only:
        return 0
    write_outputs(
        result,
        server_products=BASE_DIR / "data" / "imported_products.json",
        server_models=BASE_DIR / "data" / "imported_models.json",
        dart_output=BASE_DIR.parent / "lib" / "data" / "generated_product_catalog.dart",
    )
    print("앱·서버 생성 파일을 갱신했습니다.")
    return 0


def manage_catalog(args: argparse.Namespace) -> int:
    store = CatalogStore(CATALOG_DATABASE_PATH)
    if args.managed_command == "list":
        status = ReviewStatus(args.status) if args.status else None
        items = store.list(status)
        for product in items:
            print(
                f"{product.id} | {product.reviewStatus.value} | "
                f"{product.brand} {product.modelName or product.seriesName}"
            )
        if not items:
            print("조건에 맞는 운영 제품이 없습니다.")
        return 0
    if args.managed_command == "audit":
        for event in store.audit_log(args.product, limit=args.limit):
            print(
                f"{event.auditId} | {event.changedAt.isoformat()} | "
                f"{event.productId} | {event.action} | "
                f"{event.reviewStatus.value} | {event.operator} | {event.note}"
            )
        return 0
    if args.managed_command == "backup":
        destination = args.destination.resolve()
        store.backup_to(destination)
        print(f"운영 카탈로그 백업: {destination}")
        return 0
    if args.managed_command == "restore-drill":
        backup = args.backup.resolve()
        destination = args.destination.resolve()
        try:
            report = store.restore_drill(backup, destination)
        except (CatalogWorkflowError, OSError) as error:
            print(f"운영 카탈로그 복구 훈련 오류: {error}")
            return 1
        print(f"복구 훈련 완료: {destination}")
        print(
            f"  integrity={report['integrity']} | "
            f"products={report['products']} | "
            f"auditEvents={report['auditEvents']}"
        )
        return 0
    try:
        if args.managed_command == "import":
            payload = args.source.resolve().read_text(encoding="utf-8")
            product = CatalogProduct.model_validate_json(payload)
            updated = store.upsert(
                product,
                operator=args.operator,
                note=args.note,
            )
        else:
            updated = store.transition(
                args.product_id,
                target=ReviewStatus(args.status),
                operator=args.operator,
                note=args.note,
            )
    except (CatalogWorkflowError, ValueError, OSError) as error:
        print(f"운영 카탈로그 오류: {error}")
        return 1
    print(f"{updated.id} -> {updated.reviewStatus.value}")
    return 0


def main() -> int:
    args = build_parser().parse_args()
    if args.command == "catalog":
        return catalog_report(args.stale_days)
    if args.command == "release":
        return release_report(
            args.products,
            args.output,
            args.allow_blocked,
        )
    if args.command == "import-catalog":
        return import_catalog_data(args.source, args.check)
    if args.command == "managed-catalog":
        return manage_catalog(args)
    if args.submission_command == "list":
        return list_submissions(args.status)
    return update_submission(
        args.tracking_token,
        args.status,
        args.operator,
        args.note,
    )


if __name__ == "__main__":
    raise SystemExit(main())
