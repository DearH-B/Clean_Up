import os
from dataclasses import dataclass
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parents[1]


def _split_csv(value: str) -> list[str]:
    return [item.strip() for item in value.split(",") if item.strip()]


@dataclass(frozen=True)
class ServerSettings:
    environment: str
    catalog_database_path: Path
    submissions_path: Path
    allowed_origins: list[str]
    admin_api_key: str | None

    @property
    def admin_api_enabled(self) -> bool:
        return bool(self.admin_api_key)


def load_settings() -> ServerSettings:
    return ServerSettings(
        environment=os.environ.get("CARELOG_ENV", "local"),
        catalog_database_path=Path(
            os.environ.get(
                "CATALOG_DATABASE_PATH",
                BASE_DIR / "data" / "catalog_admin.db",
            )
        ),
        submissions_path=Path(
            os.environ.get(
                "SUBMISSIONS_PATH",
                BASE_DIR / "data" / "submissions.json",
            )
        ),
        allowed_origins=_split_csv(os.environ.get("CARELOG_ALLOWED_ORIGINS", "")),
        admin_api_key=os.environ.get("CATALOG_ADMIN_API_KEY"),
    )
