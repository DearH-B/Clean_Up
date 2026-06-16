import os

from fastapi import FastAPI, Header, HTTPException, Query, Response
from fastapi.middleware.cors import CORSMiddleware

from .catalog import ProductCatalog
from .catalog_store import CatalogStore, CatalogWorkflowError
from .config import BASE_DIR, load_settings
from .diagnostics import ProductDiagnosticCatalog
from .schemas import (
    CatalogAuditEvent,
    CatalogTransitionRequest,
    CatalogProduct,
    ModelListResponse,
    DiagnosticListResponse,
    ProductSearchResponse,
    StringListResponse,
    SubmissionCreate,
    SubmissionResponse,
    SubmissionStatus,
    SubmissionStatusUpdateRequest,
)
from .submissions import SubmissionStore

settings = load_settings()
catalog_store = CatalogStore(settings.catalog_database_path)
catalog = ProductCatalog(
    BASE_DIR / "data" / "products.json",
    managed_products=catalog_store.published(),
)
submissions = SubmissionStore(settings.submissions_path)
diagnostics = ProductDiagnosticCatalog(
    BASE_DIR / "data" / "product_diagnostics.json"
)

app = FastAPI(
    title="Home Product Care Catalog API",
    version="0.1.0",
    description="Curated product cleaning and maintenance information.",
)

if settings.allowed_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_origins,
        allow_credentials=False,
        allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allow_headers=["Content-Type", "X-Admin-Key"],
    )


@app.get("/health")
def health() -> dict[str, str | int]:
    return {
        "status": "ok",
        "environment": settings.environment,
        "catalogProducts": len(catalog.search("")),
        "managedProducts": len(catalog_store.list()),
        "diagnosticVersion": diagnostics.version,
        "adminApiEnabled": int(settings.admin_api_enabled),
    }


@app.get("/v1/diagnostics", response_model=DiagnosticListResponse)
def list_diagnostics(
    product_type: str = Query(min_length=1, max_length=120, alias="productType"),
) -> DiagnosticListResponse:
    items = diagnostics.for_product_type(product_type)
    return DiagnosticListResponse(
        items=items,
        total=len(items),
        productType=product_type,
        version=diagnostics.version,
    )


@app.get("/ready")
def readiness() -> dict[str, str | int]:
    report = catalog_store.integrity_report()
    if report["integrity"] != "ok":
        raise HTTPException(
            status_code=503,
            detail="Catalog database integrity check failed",
        )
    return {
        "status": "ready",
        "databaseIntegrity": report["integrity"],
        "managedProducts": report["products"],
        "auditEvents": report["auditEvents"],
        "catalogProducts": len(catalog.search("")),
    }


@app.get("/v1/products", response_model=ProductSearchResponse)
def search_products(
    q: str = Query(default="", max_length=120),
    category: str | None = Query(default=None, max_length=80),
    brand: str | None = Query(default=None, max_length=80),
    limit: int = Query(default=20, ge=1, le=100),
) -> ProductSearchResponse:
    matches = catalog.search(q, category=category, brand=brand)
    return ProductSearchResponse(
        items=matches[:limit],
        total=len(matches),
        query=q,
    )


@app.get("/v1/products/{product_id}", response_model=CatalogProduct)
def get_product(product_id: str) -> CatalogProduct:
    product = catalog.get(product_id)
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    return product


@app.get("/v1/brands", response_model=StringListResponse)
def list_brands(
    category: str = Query(min_length=1, max_length=80),
) -> StringListResponse:
    items = catalog.brands(category)
    return StringListResponse(items=items, total=len(items))


@app.get("/v1/models", response_model=ModelListResponse)
def list_models(
    category: str = Query(min_length=1, max_length=80),
    brand: str = Query(min_length=1, max_length=80),
    q: str = Query(default="", max_length=120),
    limit: int = Query(default=50, ge=1, le=100),
) -> ModelListResponse:
    matches = catalog.models(category=category, brand=brand, query=q)
    return ModelListResponse(items=matches[:limit], total=len(matches))


@app.post(
    "/v1/submissions",
    response_model=SubmissionResponse,
    status_code=201,
)
def create_submission(payload: SubmissionCreate) -> SubmissionResponse:
    return submissions.create(payload)


@app.get(
    "/v1/submissions/{tracking_token}",
    response_model=SubmissionResponse,
)
def get_submission(tracking_token: str) -> SubmissionResponse:
    submission = submissions.get(tracking_token)
    if submission is None:
        raise HTTPException(status_code=404, detail="Submission not found")
    return submission


def _require_admin_key(x_admin_key: str | None) -> None:
    configured = os.environ.get("CATALOG_ADMIN_API_KEY") or settings.admin_api_key
    if not configured:
        raise HTTPException(
            status_code=503,
            detail="Catalog admin API is not configured",
        )
    if x_admin_key != configured:
        raise HTTPException(status_code=401, detail="Invalid admin key")


@app.get("/v1/admin/products", response_model=list[CatalogProduct])
def list_admin_products(
    status: str | None = Query(default=None),
    x_admin_key: str | None = Header(default=None),
) -> list[CatalogProduct]:
    _require_admin_key(x_admin_key)
    review_status = None
    if status is not None:
        try:
            from .schemas import ReviewStatus

            review_status = ReviewStatus(status)
        except ValueError as error:
            raise HTTPException(status_code=400, detail="Invalid status") from error
    return catalog_store.list(review_status)


@app.get("/v1/admin/submissions", response_model=list[SubmissionResponse])
def list_admin_submissions(
    status: SubmissionStatus | None = Query(default=None),
    x_admin_key: str | None = Header(default=None),
) -> list[SubmissionResponse]:
    _require_admin_key(x_admin_key)
    return submissions.list(status)


@app.post(
    "/v1/admin/submissions/{tracking_token}/status",
    response_model=SubmissionResponse,
)
def update_admin_submission_status(
    tracking_token: str,
    request: SubmissionStatusUpdateRequest,
    x_admin_key: str | None = Header(default=None),
) -> SubmissionResponse:
    _require_admin_key(x_admin_key)
    submission = submissions.update_status(
        tracking_token,
        status=request.status,
        operator=request.operator,
        note=request.note,
    )
    if submission is None:
        raise HTTPException(status_code=404, detail="Submission not found")
    return submission


@app.get("/v1/admin/audit-log", response_model=list[CatalogAuditEvent])
def list_catalog_audit_log(
    product_id: str | None = Query(default=None, max_length=160),
    limit: int = Query(default=100, ge=1, le=500),
    x_admin_key: str | None = Header(default=None),
) -> list[CatalogAuditEvent]:
    _require_admin_key(x_admin_key)
    return catalog_store.audit_log(product_id, limit=limit)


@app.put("/v1/admin/products/{product_id}", response_model=CatalogProduct)
def upsert_admin_product(
    product_id: str,
    product: CatalogProduct,
    operator: str = Query(min_length=1, max_length=120),
    note: str = Query(min_length=1, max_length=1000),
    x_admin_key: str | None = Header(default=None),
) -> CatalogProduct:
    _require_admin_key(x_admin_key)
    if product.id != product_id:
        raise HTTPException(status_code=400, detail="Product ID mismatch")
    try:
        return catalog_store.upsert(product, operator=operator, note=note)
    except CatalogWorkflowError as error:
        raise HTTPException(status_code=409, detail=str(error)) from error


@app.post(
    "/v1/admin/products/{product_id}/transition",
    response_model=CatalogProduct,
)
def transition_admin_product(
    product_id: str,
    request: CatalogTransitionRequest,
    x_admin_key: str | None = Header(default=None),
) -> CatalogProduct:
    _require_admin_key(x_admin_key)
    try:
        product = catalog_store.transition(
            product_id,
            target=request.targetStatus,
            operator=request.operator,
            note=request.note,
        )
    except KeyError as error:
        raise HTTPException(status_code=404, detail="Product not found") from error
    except CatalogWorkflowError as error:
        raise HTTPException(status_code=409, detail=str(error)) from error
    catalog.replace_managed_products(catalog_store.published())
    return product


@app.delete(
    "/v1/admin/products/{product_id}",
    status_code=204,
)
def delete_admin_product(
    product_id: str,
    operator: str = Query(min_length=1, max_length=120),
    x_admin_key: str | None = Header(default=None),
) -> Response:
    _require_admin_key(x_admin_key)
    try:
        deleted = catalog_store.delete_draft(product_id, operator=operator)
    except CatalogWorkflowError as error:
        raise HTTPException(status_code=409, detail=str(error)) from error
    if not deleted:
        raise HTTPException(status_code=404, detail="Product not found")
    catalog.replace_managed_products(catalog_store.published())
    return Response(status_code=204)
