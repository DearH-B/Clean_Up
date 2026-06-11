import argparse
from collections import Counter
from datetime import date
from pathlib import Path

from app.catalog import ProductCatalog
from app.schemas import SubmissionStatus
from app.submissions import SubmissionStore


BASE_DIR = Path(__file__).resolve().parent
CATALOG_PATH = BASE_DIR / "data" / "products.json"
SUBMISSIONS_PATH = BASE_DIR / "data" / "submissions.json"


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


def main() -> int:
    args = build_parser().parse_args()
    if args.command == "catalog":
        return catalog_report(args.stale_days)
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
