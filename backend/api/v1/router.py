from fastapi import APIRouter

from api.v1.ai_generate import router as ai_router
from api.v1.albums import router as albums_router
from api.v1.auth import router as auth_router
from api.v1.payments import router as payments_router
from api.v1.photos import router as photos_router

router = APIRouter()

router.include_router(auth_router, prefix="/auth", tags=["Auth"])
router.include_router(photos_router, prefix="/photos", tags=["Photos"])
router.include_router(albums_router, prefix="/albums", tags=["Albums"])
router.include_router(ai_router, prefix="/ai", tags=["AI Generation"])
router.include_router(payments_router, prefix="/payments", tags=["Payments"])
