from pathlib import Path

from fastapi import FastAPI, HTTPException, Query

from .catalog import ProductCatalog
from .schemas import CatalogProduct, ProductSearchResponse

BASE_DIR = Path(__file__).resolve().parents[1]
catalog = ProductCatalog(BASE_DIR / "data" / "products.json")

app = FastAPI(
    title="Home Product Care Catalog API",
    version="0.1.0",
    description="Curated product cleaning and maintenance information.",
)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/v1/products", response_model=ProductSearchResponse)
def search_products(
    q: str = Query(default="", max_length=120),
    category: str | None = Query(default=None, max_length=80),
    brand: str | None = Query(default=None, max_length=80),
    limit: int = Query(default=20, ge=1, le=100),
) -> ProductSearchResponse:
    items = catalog.search(q, category=category, brand=brand)[:limit]
    return ProductSearchResponse(items=items, total=len(items), query=q)


@app.get("/v1/products/{product_id}", response_model=CatalogProduct)
def get_product(product_id: str) -> CatalogProduct:
    product = catalog.get(product_id)
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    return product
