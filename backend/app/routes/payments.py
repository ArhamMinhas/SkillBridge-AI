"""Stripe payment routes. See docs/frontend_design_spec.md section 9 for the
full client<->backend<->Stripe sequence diagram.
"""
import stripe
from fastapi import APIRouter, Depends, HTTPException, Request, status

from app.config import get_settings
from app.firebase.auth import CurrentUser, get_current_user
from app.payments import stripe_client
from app.schemas.payment import CreateSubscriptionIntentRequest, CreateSubscriptionIntentResponse

router = APIRouter(prefix="/payments", tags=["payments"])
_settings = get_settings()


@router.post("/create-subscription-intent", response_model=CreateSubscriptionIntentResponse)
async def create_subscription_intent(
    payload: CreateSubscriptionIntentRequest,
    current_user: CurrentUser = Depends(get_current_user),
):
    try:
        result = stripe_client.create_subscription_intent(
            uid=current_user.uid, email=current_user.email, plan=payload.plan
        )
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc))
    except stripe.error.StripeError as exc:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=str(exc))

    return result


@router.post("/cancel-subscription")
async def cancel_subscription(current_user: CurrentUser = Depends(get_current_user)):
    try:
        stripe_client.cancel_subscription(current_user.uid)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc))
    except stripe.error.StripeError as exc:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=str(exc))

    return {"status": "canceled"}


@router.post("/webhook")
async def stripe_webhook(request: Request):
    """Public endpoint (no Firebase auth — Stripe calls this directly) but
    authenticated via Stripe's own signature verification instead."""
    payload = await request.body()
    sig_header = request.headers.get("stripe-signature", "")

    try:
        event = stripe_client.construct_webhook_event(payload, sig_header)
    except (ValueError, stripe.error.SignatureVerificationError):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid webhook signature")

    event_type = event["type"]
    data_object = event["data"]["object"]

    if event_type in ("payment_intent.succeeded", "invoice.paid"):
        stripe_client.handle_payment_succeeded(data_object)

    return {"received": True}
