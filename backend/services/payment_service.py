import logging
from datetime import datetime, timedelta, timezone

import httpx
from supabase import Client

from config.settings import Settings

logger = logging.getLogger(__name__)

APPLE_PRODUCTION_URL = "https://buy.itunes.apple.com/verifyReceipt"
APPLE_SANDBOX_URL = "https://sandbox.itunes.apple.com/verifyReceipt"


class PaymentService:
    def __init__(self, settings: Settings, supabase: Client):
        self.settings = settings
        self.supabase = supabase

    async def verify_apple_receipt(self, receipt_data: str) -> dict:
        """Verify an iOS App Store receipt using Apple's verifyReceipt endpoint.

        In production mode, tries the production URL first. If Apple returns
        status 21007 (sandbox receipt sent to production), falls back to the
        sandbox URL automatically. In development/sandbox mode, hits the
        sandbox URL directly.
        """
        payload = {
            "receipt-data": receipt_data,
            "password": self.settings.APPLE_SHARED_SECRET,
            "exclude-old-transactions": True,
        }

        async with httpx.AsyncClient(timeout=30.0) as client:
            if self.settings.APP_ENV == "production":
                # Try production first
                response = await client.post(APPLE_PRODUCTION_URL, json=payload)
                result = response.json()

                # Status 21007 means sandbox receipt was sent to production
                if result.get("status") == 21007:
                    logger.info(
                        "Apple receipt is sandbox; retrying against sandbox URL"
                    )
                    response = await client.post(APPLE_SANDBOX_URL, json=payload)
                    result = response.json()
            else:
                # Development/sandbox mode — go straight to sandbox
                response = await client.post(APPLE_SANDBOX_URL, json=payload)
                result = response.json()

        status_code = result.get("status", -1)
        if status_code != 0:
            logger.error("Apple receipt verification failed with status %s", status_code)
            raise ValueError(f"Apple receipt verification failed: status {status_code}")

        return result

    async def verify_google_receipt(
        self, purchase_token: str, product_id: str
    ) -> dict:
        """Verify a Google Play purchase.

        This is a stub implementation. Full verification requires the
        google-auth library and Google Play Developer API. For now we
        validate that the token is present and return a success dict.
        """
        if not purchase_token:
            raise ValueError("Google purchase token is empty")

        logger.info(
            "Google receipt verification stub for product_id=%s", product_id
        )

        # Stub: in production, call the Google Play Developer API
        # using the service account key from settings.
        return {
            "valid": True,
            "product_id": product_id,
            "purchase_token": purchase_token,
            "expiry_time_millis": int(
                (datetime.now(timezone.utc) + timedelta(days=30)).timestamp() * 1000
            ),
        }

    async def process_subscription(
        self,
        user_id: str,
        platform: str,
        receipt_data: str,
        product_id: str,
    ) -> dict:
        """Verify the receipt, activate the subscription, and log the transaction.

        Returns a dict with plan info suitable for building a SubscriptionResponse.
        """
        # 1. Verify the receipt with the appropriate platform
        if platform == "ios":
            verification = await self.verify_apple_receipt(receipt_data)
        elif platform == "android":
            verification = await self.verify_google_receipt(receipt_data, product_id)
        else:
            raise ValueError(f"Unsupported platform: {platform}")

        # 2. Calculate expiration (30 days from now for a monthly subscription)
        expires_at = datetime.now(timezone.utc) + timedelta(days=30)

        # 3. Update the user's plan in the users table
        self.supabase.table("users").update(
            {
                "plan": "premium",
                "plan_expires_at": expires_at.isoformat(),
            }
        ).eq("id", user_id).execute()

        # 4. Log the transaction in the payments table
        self.supabase.table("payments").insert(
            {
                "user_id": user_id,
                "platform": platform,
                "product_id": product_id,
                "receipt_data": receipt_data,
                "status": "active",
                "expires_at": expires_at.isoformat(),
            }
        ).execute()

        logger.info(
            "Subscription activated for user %s on %s, expires %s",
            user_id,
            platform,
            expires_at.isoformat(),
        )

        return {
            "plan": "premium",
            "is_active": True,
            "expires_at": expires_at,
            "product_id": product_id,
        }

    async def cancel_subscription(self, user_id: str) -> dict:
        """Cancel the user's subscription by reverting to the free plan."""
        self.supabase.table("users").update(
            {
                "plan": "free",
                "plan_expires_at": None,
            }
        ).eq("id", user_id).execute()

        logger.info("Subscription cancelled for user %s", user_id)

        return {
            "plan": "free",
            "is_active": False,
            "expires_at": None,
            "product_id": None,
        }

    async def get_subscription_status(self, user_id: str) -> dict:
        """Get the current subscription status for a user."""
        result = (
            self.supabase.table("users")
            .select("plan, plan_expires_at")
            .eq("id", user_id)
            .single()
            .execute()
        )

        if not result.data:
            return {
                "plan": "free",
                "is_active": False,
                "expires_at": None,
                "product_id": None,
            }

        plan = result.data.get("plan", "free")
        expires_at_raw = result.data.get("plan_expires_at")

        # Parse the expiration timestamp
        expires_at = None
        is_active = plan == "premium"
        if expires_at_raw:
            expires_at = datetime.fromisoformat(expires_at_raw)
            # If the plan is premium but expired, treat as inactive
            if expires_at < datetime.now(timezone.utc):
                is_active = False

        return {
            "plan": plan,
            "is_active": is_active,
            "expires_at": expires_at,
            "product_id": None,
        }
