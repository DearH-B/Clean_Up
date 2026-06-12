from datetime import date, datetime
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
    recurrenceDays: int = Field(ge=0)
    estimatedMinutes: int = Field(ge=0)
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


class StringListResponse(BaseModel):
    items: list[str]
    total: int


class CatalogModelOption(BaseModel):
    model_config = ConfigDict(extra="forbid")

    categoryName: str
    brand: str
    modelName: str
    displayName: str
    releaseYear: int | None = None
    imageUrl: str | None = None
    productUrl: str | None = None
    sourceCheckedAt: date
    reviewStatus: ReviewStatus


class ModelListResponse(BaseModel):
    items: list[CatalogModelOption]
    total: int


class SubmissionType(StrEnum):
    missingProduct = "missingProduct"
    incorrectInfo = "incorrectInfo"
    brokenLink = "brokenLink"
    incorrectGuide = "incorrectGuide"
    unsafeGuide = "unsafeGuide"
    officialSource = "officialSource"


class SubmissionStatus(StrEnum):
    received = "received"
    investigating = "investigating"
    confirmed = "confirmed"
    completed = "completed"
    rejected = "rejected"


class SubmissionReviewEvent(BaseModel):
    model_config = ConfigDict(extra="forbid")

    status: SubmissionStatus
    operator: str
    changedAt: datetime
    note: str


class SubmissionCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    clientSubmissionId: str = Field(min_length=1, max_length=120)
    type: SubmissionType
    title: str = Field(min_length=1, max_length=160)
    details: str = Field(default="", max_length=2000)
    productId: str | None = Field(default=None, max_length=160)
    productName: str | None = Field(default=None, max_length=160)
    categoryName: str | None = Field(default=None, max_length=120)
    brand: str | None = Field(default=None, max_length=120)
    modelName: str | None = Field(default=None, max_length=160)
    sourceUrl: HttpUrl | None = None
    createdAt: datetime


class SubmissionResponse(SubmissionCreate):
    trackingToken: str
    status: SubmissionStatus
    statusMessage: str | None = None
    updatedAt: datetime
    reviewHistory: list[SubmissionReviewEvent] = Field(default_factory=list)
