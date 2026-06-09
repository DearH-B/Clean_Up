from datetime import date
from enum import StrEnum

from pydantic import BaseModel, ConfigDict, Field, HttpUrl


class ReviewStatus(StrEnum):
    draft = "draft"
    reviewed = "reviewed"
    verified = "verified"


class SourceType(StrEnum):
    officialProduct = "officialProduct"
    officialManual = "officialManual"
    officialVideo = "officialVideo"
    officialSupport = "officialSupport"
    retailer = "retailer"
    priceComparison = "priceComparison"
    installer = "installer"
    similarProduct = "similarProduct"
    generalGuidance = "generalGuidance"


class ProductSource(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: str
    title: str
    url: str | None = None
    type: SourceType
    publisher: str
    checkedAt: date
    supports: list[str] = Field(default_factory=list)
    isOfficial: bool
    isActive: bool = True


class ReviewRecord(BaseModel):
    model_config = ConfigDict(extra="forbid")

    status: ReviewStatus
    reviewer: str
    reviewedAt: date
    note: str


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
    sources: list[ProductSource] = Field(min_length=1)
    specSourceIds: dict[str, list[str]] = Field(default_factory=dict)
    stepSourceIds: dict[str, list[str]] = Field(default_factory=dict)
    reviewHistory: list[ReviewRecord] = Field(min_length=1)
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
    officialManualUrl: str | None = None
    supportUrl: str | None = None
    servicePhone: str | None = None
    releaseYear: int | None = None
    isDiscontinued: bool | None = None
    imageUrl: str | None = None
    consumables: list[str] = Field(default_factory=list)
    installationType: str | None = None


class ProductSearchResponse(BaseModel):
    items: list[CatalogProduct]
    total: int
    query: str
