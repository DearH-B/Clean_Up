from datetime import date
from enum import StrEnum

from pydantic import BaseModel, ConfigDict, Field, HttpUrl


class ReviewStatus(StrEnum):
    draft = "draft"
    reviewed = "reviewed"
    verified = "verified"


class CleaningProduct(BaseModel):
    model_config = ConfigDict(extra="forbid")

    brand: str
    name: str
    reason: str
    url: HttpUrl
    isSponsored: bool = False


class CatalogProduct(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: str
    name: str
    type: str
    categoryName: str
    brand: str
    manufacturer: str
    modelName: str
    summary: str
    frequency: str
    recurrenceDays: int = Field(ge=1)
    estimatedMinutes: int = Field(ge=1)
    productMethod: str
    guideStatus: str
    guideBasis: str
    guideSourceType: str
    matchLevelLabel: str
    sourceTitle: str
    sourceUrl: str
    sourceCheckedAt: date
    productSpecs: list[str]
    supplies: list[str]
    recommendedSupplies: list[str]
    recommendedProducts: list[CleaningProduct]
    cautions: list[str]
    steps: list[str]
    guideVideoUrl: str | None = None
    guideVideoTitle: str | None = None
    guideVideoChannel: str | None = None
    keywords: list[str] = Field(default_factory=list)
    reviewStatus: ReviewStatus
    reviewedBy: str | None = None
    reviewNote: str | None = None


class ProductSearchResponse(BaseModel):
    items: list[CatalogProduct]
    total: int
    query: str
