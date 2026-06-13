import csv
import json
import re
import zipfile
from collections import defaultdict
from dataclasses import dataclass
from datetime import date, timedelta
from pathlib import Path
from xml.etree import ElementTree

from .schemas import CatalogModelOption, CatalogProduct


SHEETS = {
    "products",
    "sources",
    "steps",
    "specs",
    "lists",
    "consumables",
    "recommendations",
    "models",
}
LIST_KINDS = {
    "supply": "supplies",
    "recommendedSupply": "recommendedSupplies",
    "caution": "cautions",
    "keyword": "keywords",
    "modelFeature": "modelFeatures",
}


class CatalogImportError(ValueError):
    pass


@dataclass(frozen=True)
class CatalogImportResult:
    products: list[dict[str, object]]
    models: list[dict[str, object]]


def import_catalog(source: Path) -> CatalogImportResult:
    tables = _read_tables(source)
    products = _build_products(tables)
    models = _build_models(tables)
    for product in products:
        CatalogProduct.model_validate(product)
    for model in models:
        CatalogModelOption.model_validate(model)
    return CatalogImportResult(products=products, models=models)


def write_outputs(
    result: CatalogImportResult,
    *,
    server_products: Path,
    server_models: Path,
    dart_output: Path,
) -> None:
    server_products.parent.mkdir(parents=True, exist_ok=True)
    server_models.parent.mkdir(parents=True, exist_ok=True)
    dart_output.parent.mkdir(parents=True, exist_ok=True)
    server_products.write_text(
        json.dumps(result.products, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    server_models.write_text(
        json.dumps(result.models, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    dart_output.write_text(_render_dart(result), encoding="utf-8")


def _read_tables(source: Path) -> dict[str, list[dict[str, str]]]:
    if source.is_dir():
        return {
            name: _read_csv(source / f"{name}.csv")
            for name in SHEETS
        }
    if source.suffix.lower() == ".xlsx":
        return _read_xlsx(source)
    raise CatalogImportError("입력은 CSV 폴더 또는 .xlsx 파일이어야 합니다.")


def _read_csv(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        raise CatalogImportError(f"필수 입력 파일이 없습니다: {path.name}")
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return [
            {key: (value or "").strip() for key, value in row.items()}
            for row in csv.DictReader(handle)
        ]


def _read_xlsx(path: Path) -> dict[str, list[dict[str, str]]]:
    namespace = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
    relations_ns = {
        "r": "http://schemas.openxmlformats.org/package/2006/relationships"
    }
    with zipfile.ZipFile(path) as archive:
        shared = []
        if "xl/sharedStrings.xml" in archive.namelist():
            root = ElementTree.fromstring(archive.read("xl/sharedStrings.xml"))
            shared = [
                "".join(node.text or "" for node in item.findall(".//m:t", namespace))
                for item in root.findall("m:si", namespace)
            ]
        workbook = ElementTree.fromstring(archive.read("xl/workbook.xml"))
        rels = ElementTree.fromstring(archive.read("xl/_rels/workbook.xml.rels"))
        targets = {
            rel.attrib["Id"]: rel.attrib["Target"]
            for rel in rels.findall("r:Relationship", relations_ns)
        }
        tables = {}
        for sheet in workbook.findall("m:sheets/m:sheet", namespace):
            name = sheet.attrib["name"]
            if name not in SHEETS:
                continue
            relation_id = sheet.attrib[
                "{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id"
            ]
            target = targets[relation_id].lstrip("/")
            if not target.startswith("xl/"):
                target = f"xl/{target}"
            root = ElementTree.fromstring(archive.read(target))
            rows = []
            for row in root.findall(".//m:sheetData/m:row", namespace):
                values = []
                expected_column = 0
                for cell in row.findall("m:c", namespace):
                    reference = cell.attrib.get("r", "A1")
                    column = _column_index(reference)
                    while expected_column < column:
                        values.append("")
                        expected_column += 1
                    cell_type = cell.attrib.get("t")
                    value_node = cell.find("m:v", namespace)
                    inline = cell.find("m:is/m:t", namespace)
                    value = ""
                    if inline is not None:
                        value = inline.text or ""
                    elif value_node is not None:
                        value = value_node.text or ""
                        if cell_type == "s":
                            value = shared[int(value)]
                        elif cell_type == "b":
                            value = "true" if value == "1" else "false"
                    values.append(value)
                    expected_column += 1
                rows.append(values)
            if not rows:
                tables[name] = []
                continue
            headers = [str(value).strip() for value in rows[0]]
            tables[name] = [
                {
                    header: str(row[index]).strip() if index < len(row) else ""
                    for index, header in enumerate(headers)
                    if header
                }
                for row in rows[1:]
                if any(str(value).strip() for value in row)
            ]
        missing = SHEETS - set(tables)
        if missing:
            raise CatalogImportError(
                f"엑셀에 필수 시트가 없습니다: {', '.join(sorted(missing))}"
            )
        return tables


def _column_index(reference: str) -> int:
    letters = re.match(r"[A-Z]+", reference)
    if letters is None:
        return 0
    result = 0
    for character in letters.group(0):
        result = result * 26 + ord(character) - ord("A") + 1
    return result - 1


def _build_products(
    tables: dict[str, list[dict[str, str]]],
) -> list[dict[str, object]]:
    rows = [row for row in tables["products"] if _bool(row.get("publish"))]
    ids = [row.get("id", "") for row in rows]
    duplicates = sorted({item for item in ids if ids.count(item) > 1})
    if duplicates:
        raise CatalogImportError(f"중복 제품 ID: {', '.join(duplicates)}")

    related = {
        name: _group(tables[name])
        for name in (
            "sources",
            "steps",
            "specs",
            "lists",
            "consumables",
            "recommendations",
        )
    }
    products = []
    for row in rows:
        product_id = _required(row, "id")
        sources = related["sources"][product_id]
        source_ids = {item.get("sourceId", "") for item in sources}
        if not sources:
            raise CatalogImportError(f"{product_id}: 출처가 없습니다.")
        steps = _ordered(related["steps"][product_id])
        if not steps:
            raise CatalogImportError(f"{product_id}: 관리 단계가 없습니다.")
        specs = _ordered(related["specs"][product_id])
        lists = defaultdict(list)
        for item in _ordered(related["lists"][product_id]):
            kind = item.get("kind", "")
            if kind not in LIST_KINDS:
                raise CatalogImportError(f"{product_id}: 알 수 없는 목록 종류 {kind}")
            lists[LIST_KINDS[kind]].append(_required(item, "value"))
        spec_references = {
            _required(item, "label"): _references(
                product_id, item.get("sourceIds", ""), source_ids
            )
            for item in specs
        }
        step_references = {
            str(index): _references(
                product_id, item.get("sourceIds", ""), source_ids
            )
            for index, item in enumerate(steps)
        }
        checked_at = _date(row.get("sourceCheckedAt"))
        review_status = _required(row, "reviewStatus")
        product = {
            "id": product_id,
            "name": _required(row, "name"),
            "type": _required(row, "type"),
            "categoryName": _required(row, "categoryName"),
            "brand": _required(row, "brand"),
            "manufacturer": _required(row, "manufacturer"),
            "modelName": row.get("modelName", ""),
            "seriesName": row.get("seriesName", ""),
            "summary": _required(row, "summary"),
            "frequency": _required(row, "frequency"),
            "recurrenceDays": _integer(row.get("recurrenceDays")),
            "estimatedMinutes": _integer(row.get("estimatedMinutes")),
            "productMethod": _required(row, "productMethod"),
            "guideStatus": _required(row, "guideStatus"),
            "guideBasis": _required(row, "guideBasis"),
            "guideSourceType": _required(row, "guideSourceType"),
            "matchLevelLabel": _required(row, "matchLevelLabel"),
            "sourceTitle": _required(row, "sourceTitle"),
            "sourceUrl": row.get("sourceUrl", ""),
            "sourceCheckedAt": checked_at,
            "sources": [_source(item) for item in sources],
            "specSourceIds": spec_references,
            "stepSourceIds": step_references,
            "reviewHistory": [
                {
                    "status": review_status,
                    "reviewer": _required(row, "reviewedBy"),
                    "reviewedAt": checked_at,
                    "note": _required(row, "reviewNote"),
                }
            ],
            "productSpecs": [
                f"{_required(item, 'label')}: {_required(item, 'value')}"
                for item in specs
            ],
            "supplies": lists["supplies"],
            "recommendedSupplies": lists["recommendedSupplies"],
            "recommendedProducts": [
                _recommendation(item)
                for item in related["recommendations"][product_id]
            ],
            "cautions": lists["cautions"],
            "steps": [_required(item, "text") for item in steps],
            "keywords": lists["keywords"],
            "reviewStatus": review_status,
            "reviewedBy": _required(row, "reviewedBy"),
            "reviewNote": _required(row, "reviewNote"),
            "officialManualUrl": _optional(row.get("officialManualUrl")),
            "supportUrl": _optional(row.get("supportUrl")),
            "servicePhone": _optional(row.get("servicePhone")),
            "releaseYear": _optional_integer(row.get("releaseYear")),
            "isDiscontinued": _bool(row.get("isDiscontinued")),
            "imageUrl": _optional(row.get("imageUrl")),
            "modelFeatures": lists["modelFeatures"],
            "consumables": [
                _required(item, "name")
                for item in related["consumables"][product_id]
            ],
            "consumableDetails": [
                _consumable(item)
                for item in related["consumables"][product_id]
            ],
            "installationType": _optional(row.get("installationType")),
        }
        products.append(product)
    return products


def _build_models(
    tables: dict[str, list[dict[str, str]]],
) -> list[dict[str, object]]:
    models = []
    for row in tables["models"]:
        if not _bool(row.get("publish")):
            continue
        models.append(
            {
                "categoryName": _required(row, "categoryName"),
                "brand": _required(row, "brand"),
                "modelName": _required(row, "modelName"),
                "displayName": _required(row, "displayName"),
                "releaseYear": _optional_integer(row.get("releaseYear")),
                "imageUrl": _optional(row.get("imageUrl")),
                "productUrl": _optional(row.get("productUrl")),
                "features": _split(row.get("features")),
                "sourceCheckedAt": _date(row.get("sourceCheckedAt")),
                "reviewStatus": _required(row, "reviewStatus"),
            }
        )
    return models


def _source(row: dict[str, str]) -> dict[str, object]:
    return {
        "id": _required(row, "sourceId"),
        "title": _required(row, "title"),
        "url": _optional(row.get("url")),
        "type": _required(row, "type"),
        "publisher": _required(row, "publisher"),
        "checkedAt": _date(row.get("checkedAt")),
        "supports": _split(row.get("supports")),
        "isOfficial": _bool(row.get("isOfficial")),
        "isActive": _bool(row.get("isActive"), default=True),
    }


def _consumable(row: dict[str, str]) -> dict[str, object]:
    return {
        "id": _required(row, "id"),
        "name": _required(row, "name"),
        "type": _required(row, "type"),
        "replacementDays": _integer(row.get("replacementDays")),
        "compatibilityLabel": _required(row, "compatibilityLabel"),
        "partNumber": _optional(row.get("partNumber")),
        "purchaseUrl": _optional(row.get("purchaseUrl")),
        "isSponsored": _bool(row.get("isSponsored")),
        "note": _optional(row.get("note")),
    }


def _recommendation(row: dict[str, str]) -> dict[str, object]:
    return {
        "brand": _required(row, "brand"),
        "name": _required(row, "name"),
        "reason": _required(row, "reason"),
        "url": _required(row, "url"),
        "isSponsored": _bool(row.get("isSponsored")),
    }


def _group(rows: list[dict[str, str]]) -> defaultdict[str, list[dict[str, str]]]:
    grouped: defaultdict[str, list[dict[str, str]]] = defaultdict(list)
    for row in rows:
        grouped[row.get("productId", "")].append(row)
    return grouped


def _ordered(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    return sorted(rows, key=lambda item: _integer(item.get("order")))


def _references(product_id: str, value: str, source_ids: set[str]) -> list[str]:
    references = _split(value)
    missing = set(references) - source_ids
    if missing:
        raise CatalogImportError(
            f"{product_id}: 등록되지 않은 출처 참조 {', '.join(sorted(missing))}"
        )
    return references


def _required(row: dict[str, str], key: str) -> str:
    value = (row.get(key) or "").strip()
    if not value:
        identity = row.get("id") or row.get("productId") or "행"
        raise CatalogImportError(f"{identity}: 필수값 {key} 누락")
    return value


def _split(value: str | None) -> list[str]:
    return [item.strip() for item in (value or "").split("|") if item.strip()]


def _integer(value: str | None) -> int:
    try:
        return int(float(value or "0"))
    except ValueError as error:
        raise CatalogImportError(f"숫자 형식이 아닙니다: {value}") from error


def _optional_integer(value: str | None) -> int | None:
    return None if not (value or "").strip() else _integer(value)


def _date(value: str | None) -> str:
    normalized = (value or "").strip()
    if not normalized:
        raise CatalogImportError("날짜 값이 비어 있습니다.")
    if re.fullmatch(r"\d+(?:\.0+)?", normalized):
        converted = date(1899, 12, 30) + timedelta(days=int(float(normalized)))
        return converted.isoformat()
    try:
        return date.fromisoformat(normalized).isoformat()
    except ValueError as error:
        raise CatalogImportError(f"날짜는 YYYY-MM-DD 형식이어야 합니다: {value}") from error


def _bool(value: str | None, *, default: bool = False) -> bool:
    normalized = (value or "").strip().lower()
    if not normalized:
        return default
    if normalized in {"true", "1", "yes", "y"}:
        return True
    if normalized in {"false", "0", "no", "n"}:
        return False
    raise CatalogImportError(f"참/거짓 형식이 아닙니다: {value}")


def _optional(value: str | None) -> str | None:
    normalized = (value or "").strip()
    return normalized or None


def _render_dart(result: CatalogImportResult) -> str:
    products = json.dumps(result.products, ensure_ascii=False, indent=2)
    models = json.dumps(result.models, ensure_ascii=False, indent=2)
    products = products.replace("$", r"\$")
    models = models.replace("$", r"\$")
    return (
        "// GENERATED FILE. Run `python server/manage.py import-catalog`.\n"
        "// Do not edit by hand.\n\n"
        f"const generatedProductCatalogJson = <Map<String, Object?>>{products};\n\n"
        f"const generatedModelCatalogJson = <Map<String, Object?>>{models};\n"
    )
