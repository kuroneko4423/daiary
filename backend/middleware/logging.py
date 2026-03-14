import asyncio
import json
import logging
import time

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.responses import Response

from config.database import get_admin_supabase_client
from config.settings import settings

logger = logging.getLogger("daiary")

SENSITIVE_FIELDS = {
    "password",
    "email",
    "refresh_token",
    "receipt_data",
    "token",
    "access_token",
}


def _redact(data: dict) -> dict:
    """Remove sensitive fields from a dictionary."""
    return {k: v for k, v in data.items() if k not in SENSITIVE_FIELDS}


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        start_time = time.time()
        user_id = getattr(
            getattr(request, "state", None), "user_id", None
        )

        # Capture query params
        query_params = dict(request.query_params) or None

        # Capture request body
        request_body = None
        content_type = request.headers.get("content-type", "")
        if "application/json" in content_type:
            try:
                body_bytes = await request.body()
                raw = json.loads(body_bytes)
                request_body = (
                    _redact(raw) if isinstance(raw, dict) else raw
                )
            except Exception:
                pass
        elif "multipart/form-data" in content_type:
            request_body = {"_type": "multipart/form-data"}

        # Console log
        logger.info(
            "Request: %s %s",
            request.method,
            request.url.path,
        )

        response = await call_next(request)

        duration_ms = (time.time() - start_time) * 1000
        logger.info(
            "Response: %s %s -> %d (%.1fms)",
            request.method,
            request.url.path,
            response.status_code,
            duration_ms,
        )

        # DB write (fire-and-forget)
        if settings.LOG_TO_DB:
            row = {
                "level": "INFO",
                "logger_name": "http",
                "message": (
                    f"{request.method} {request.url.path}"
                    f" -> {response.status_code}"
                ),
                "user_id": user_id,
                "request_method": request.method,
                "request_path": request.url.path,
                "status_code": response.status_code,
                "duration_ms": duration_ms,
                "extra": {
                    "query_params": query_params,
                    "request_body": request_body,
                },
            }
            try:
                loop = asyncio.get_running_loop()
                loop.create_task(self._write_log(row))
            except RuntimeError:
                pass

        return response

    @staticmethod
    async def _write_log(row: dict):
        try:
            client = get_admin_supabase_client()
            client.table("app_logs").insert(row).execute()
        except Exception:
            pass
