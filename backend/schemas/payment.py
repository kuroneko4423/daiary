from datetime import datetime

from pydantic import BaseModel


class VerifyReceiptRequest(BaseModel):
    platform: str  # "ios" or "android"
    receipt_data: str
    product_id: str


class SubscriptionResponse(BaseModel):
    plan: str
    is_active: bool
    expires_at: datetime | None = None
    product_id: str | None = None


class WebhookPayload(BaseModel):
    event_type: str
    data: dict
