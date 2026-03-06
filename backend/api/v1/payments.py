import logging

from fastapi import APIRouter, Depends, HTTPException, Request, status
from supabase import Client

from api.deps import get_settings_dep, get_supabase
from config.settings import Settings
from middleware.auth import get_current_user
from schemas.payment import SubscriptionResponse, VerifyReceiptRequest
from services.payment_service import PaymentService

logger = logging.getLogger(__name__)

router = APIRouter()


def _get_payment_service(
    settings: Settings = Depends(get_settings_dep),
    supabase: Client = Depends(get_supabase),
) -> PaymentService:
    return PaymentService(settings=settings, supabase=supabase)


@router.post("/verify-receipt", response_model=SubscriptionResponse)
async def verify_receipt(
    body: VerifyReceiptRequest,
    current_user: dict = Depends(get_current_user),
    payment_service: PaymentService = Depends(_get_payment_service),
):
    """Verify an App Store / Play Store receipt and activate the subscription."""
    if body.platform not in ("ios", "android"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="platform must be 'ios' or 'android'",
        )

    try:
        result = await payment_service.process_subscription(
            user_id=current_user["id"],
            platform=body.platform,
            receipt_data=body.receipt_data,
            product_id=body.product_id,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )
    except Exception as e:
        logger.error("Subscription processing failed: %s", e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to process subscription",
        )

    return SubscriptionResponse(**result)


@router.get("/subscription", response_model=SubscriptionResponse)
async def get_subscription(
    current_user: dict = Depends(get_current_user),
    payment_service: PaymentService = Depends(_get_payment_service),
):
    """Get the current user's subscription status."""
    try:
        result = await payment_service.get_subscription_status(
            user_id=current_user["id"],
        )
    except Exception as e:
        logger.error("Failed to get subscription status: %s", e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve subscription status",
        )

    return SubscriptionResponse(**result)


@router.post("/cancel", response_model=SubscriptionResponse)
async def cancel_subscription(
    current_user: dict = Depends(get_current_user),
    payment_service: PaymentService = Depends(_get_payment_service),
):
    """Cancel the current user's subscription."""
    try:
        result = await payment_service.cancel_subscription(
            user_id=current_user["id"],
        )
    except Exception as e:
        logger.error("Subscription cancellation failed: %s", e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to cancel subscription",
        )

    return SubscriptionResponse(**result)


@router.post("/webhook/appstore")
async def webhook_appstore(request: Request):
    """Apple App Store Server Notification webhook.

    Apple sends server-to-server notifications for subscription lifecycle
    events (renewal, cancellation, refund, etc.). No auth required -- Apple
    signs the payload with a JWS.
    """
    try:
        body = await request.json()
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid JSON payload",
        )

    notification_type = body.get("notification_type") or body.get(
        "notificationType", "unknown"
    )
    logger.info("App Store webhook received: %s", notification_type)

    # TODO: Validate the JWS signed notification, extract transaction info,
    # and update the user's subscription accordingly.

    return {"status": "ok"}


@router.post("/webhook/playstore")
async def webhook_playstore(request: Request):
    """Google Play Real-Time Developer Notification (RTDN) webhook.

    Google Cloud Pub/Sub pushes subscription state-change events here.
    No auth required at the HTTP level (Pub/Sub auth is handled separately).
    """
    try:
        body = await request.json()
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid JSON payload",
        )

    # Google wraps the notification in a Pub/Sub message envelope
    message = body.get("message", {})
    logger.info("Play Store webhook received: %s", message)

    # TODO: Decode the base64-encoded data from the Pub/Sub message,
    # determine the notification type, and update the user's subscription.

    return {"status": "ok"}
