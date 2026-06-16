from datetime import date, datetime
from enum import StrEnum

from pydantic import BaseModel, ConfigDict, Field, HttpUrl


class ReviewStatus(StrEnum):
    draft = "draft"
    reviewed = "reviewed"
    verified = "verified"


class ReleaseCheckStatus(StrEnum):
    passed = "passed"
    failed = "failed"
    blocked = "blocked"
    notApplicable = "notApplicable"


class ReleaseDecision(StrEnum):
    approved = "approved"
    blocked = "blocked"


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


class ReleaseEvidence(BaseModel):
    model_config = ConfigDict(extra="forbid")

    checkId: str
    status: ReleaseCheckStatus
    verifiedAt: date
    verifier: str
    evidence: str
    note: str = ""


class ProductReleaseProfile(BaseModel):
    model_config = ConfigDict(extra="forbid")

    productId: str
    targetRelease: str
    evidence: list[ReleaseEvidence] = Field(default_factory=list)


class AppReleaseProfile(BaseModel):
    model_config = ConfigDict(extra="forbid")

    targetRelease: str
    evidence: list[ReleaseEvidence] = Field(default_factory=list)


class ReleaseReadinessData(BaseModel):
    model_config = ConfigDict(extra="forbid")

    app: AppReleaseProfile
    products: list[ProductReleaseProfile]


class CleaningProduct(BaseModel):
    model_config = ConfigDict(extra="forbid")

    brand: str
    name: str
    reason: str
    url: HttpUrl
    isSponsored: bool = False


class ProductConsumable(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: str
    name: str
    type: str
    replacementDays: int = Field(ge=0)
    compatibilityLabel: str
    partNumber: str | None = None
    purchaseUrl: HttpUrl | None = None
    isSponsored: bool = False
    note: str | None = None


class CatalogProduct(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: str
    name: str
    type: str
    categoryName: str
    brand: str
    manufacturer: str
    modelName: str
    seriesName: str = ""
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
    modelFeatures: list[str] = Field(default_factory=list)
    consumables: list[str] = Field(default_factory=list)
    consumableDetails: list[ProductConsumable] = Field(default_factory=list)
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
    features: list[str] = Field(default_factory=list)
    sourceCheckedAt: date
    reviewStatus: ReviewStatus


class ModelListResponse(BaseModel):
    items: list[CatalogModelOption]
    total: int


class CatalogTransitionRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    targetStatus: ReviewStatus
    operator: str = Field(min_length=1, max_length=120)
    note: str = Field(min_length=1, max_length=1000)


class CatalogAuditEvent(BaseModel):
    model_config = ConfigDict(extra="forbid")

    auditId: int
    productId: str
    action: str
    reviewStatus: ReviewStatus
    operator: str
    note: str
    changedAt: datetime


class SubmissionType(StrEnum):
    missingProduct = "missingProduct"
    incorrectInfo = "incorrectInfo"
    brokenLink = "brokenLink"
    incorrectGuide = "incorrectGuide"
    unsafeGuide = "unsafeGuide"
    officialSource = "officialSource"
    appIssue = "appIssue"
    usabilityFeedback = "usabilityFeedback"


class SubmissionStatus(StrEnum):
    received = "received"
    investigating = "investigating"
    confirmed = "confirmed"
    completed = "completed"
    rejected = "rejected"


class SubmissionStatusUpdateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    status: SubmissionStatus
    operator: str = Field(min_length=1, max_length=120)
    note: str = Field(min_length=1, max_length=1000)


class DiagnosticOutcome(StrEnum):
    selfCare = "selfCare"
    checkManual = "checkManual"
    replaceConsumable = "replaceConsumable"
    stopUsing = "stopUsing"
    professionalSupport = "professionalSupport"


class DiagnosticBasisType(StrEnum):
    generalSafety = "generalSafety"
    manufacturerGuide = "manufacturerGuide"
    publicSafetyGuide = "publicSafetyGuide"
    expertReview = "expertReview"


class DiagnosticProductRecommendation(BaseModel):
    model_config = ConfigDict(extra="forbid")

    brand: str
    name: str
    reason: str
    url: str
    isSearchLink: bool = True
    isSponsored: bool = False
    suitableMaterials: list[str] = Field(default_factory=list)


class DiagnosticSource(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: str
    title: str
    url: str
    publisher: str
    type: SourceType
    checkedAt: date
    supports: list[str] = Field(default_factory=list)
    isOfficial: bool = False


class ProductDiagnostic(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: str
    productTypes: list[str] = Field(min_length=1)
    symptom: str
    question: str
    safeAction: str
    outcome: DiagnosticOutcome
    warningSigns: list[str] = Field(default_factory=list)
    steps: list[str] = Field(default_factory=list)
    tools: list[str] = Field(default_factory=list)
    recommendedProducts: list[DiagnosticProductRecommendation] = Field(
        default_factory=list
    )
    caution: str | None = None
    reviewStatus: ReviewStatus = ReviewStatus.draft
    basisType: DiagnosticBasisType = DiagnosticBasisType.generalSafety
    sourceTitle: str = "앱 생활 관리 안전 기준"
    sourceUrl: str | None = None
    reviewedAt: date
    applicableMaterials: list[str] = Field(default_factory=list)
    sources: list[DiagnosticSource] = Field(default_factory=list)
    evidenceSourceIds: list[str] = Field(default_factory=list)
    stepSourceIds: dict[str, list[str]] = Field(default_factory=dict)
    reviewHistory: list[ReviewRecord] = Field(default_factory=list)

    @property
    def requires_stop(self) -> bool:
        return self.outcome in {
            DiagnosticOutcome.stopUsing,
            DiagnosticOutcome.professionalSupport,
        }


class DiagnosticListResponse(BaseModel):
    items: list[ProductDiagnostic]
    total: int
    productType: str
    version: str


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
    screenContext: str | None = Field(default=None, max_length=240)
    createdAt: datetime


class SubmissionResponse(SubmissionCreate):
    trackingToken: str
    status: SubmissionStatus
    statusMessage: str | None = None
    updatedAt: datetime
    reviewHistory: list[SubmissionReviewEvent] = Field(default_factory=list)
