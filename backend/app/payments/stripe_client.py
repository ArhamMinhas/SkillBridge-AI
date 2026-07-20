"""Stripe integration. The Stripe SECRET key is read from settings (env var)
and never leaves this module / the backend process — the Flutter app only
ever receives the publishable key, a client secret, and an ephemeral key.
"""
import stripe

from app.config import get_settings
from app.firebase.firebase_admin_client import get_firestore_client

_settings = get_settings()
stripe.api_key = _settings.stripe_secret_key

_PLAN_PRICE_IDS = {
    "PRO": _settings.stripe_price_id_premium_monthly,
    "PRO_YEARLY": _settings.stripe_price_id_premium_yearly,
}


def get_or_create_customer(uid: str, email: str | None) -> str:
    db = get_firestore_client()
    payment_doc = db.collection("payments").document(uid).get()
    existing = payment_doc.to_dict() if payment_doc.exists else None
    if existing and existing.get("stripeCustomerId"):
        return existing["stripeCustomerId"]

    customer = stripe.Customer.create(email=email, metadata={"firebaseUid": uid})
    db.collection("payments").document(uid).set(
        {"userId": uid, "stripeCustomerId": customer.id, "status": "pending"}, merge=True
    )
    return customer.id


def create_subscription_intent(uid: str, email: str | None, plan: str) -> dict:
    price_id = _PLAN_PRICE_IDS.get(plan)
    if not price_id:
        raise ValueError(f"Unknown plan '{plan}'")

    customer_id = get_or_create_customer(uid, email)

    ephemeral_key = stripe.EphemeralKey.create(customer=customer_id, stripe_version="2024-06-20")

    subscription = stripe.Subscription.create(
        customer=customer_id,
        items=[{"price": price_id}],
        payment_behavior="default_incomplete",
        payment_settings={"save_default_payment_method": "on_subscription"},
        expand=["latest_invoice.payment_intent"],
        metadata={"firebaseUid": uid, "plan": plan},
    )

    db = get_firestore_client()
    db.collection("payments").document(uid).set(
        {
            "userId": uid,
            "stripeCustomerId": customer_id,
            "subscriptionId": subscription.id,
            "status": subscription.status,
            "plan": plan,
        },
        merge=True,
    )

    client_secret = subscription.latest_invoice.payment_intent.client_secret

    return {
        "clientSecret": client_secret,
        "customerId": customer_id,
        "ephemeralKey": ephemeral_key.secret,
        "publishableKey": "",  # supplied client-side via .env, not echoed from backend
    }


def cancel_subscription(uid: str) -> None:
    db = get_firestore_client()
    payment_doc = db.collection("payments").document(uid).get()
    data = payment_doc.to_dict() if payment_doc.exists else None
    if not data or not data.get("subscriptionId"):
        raise ValueError("No active subscription found for this user")

    stripe.Subscription.cancel(data["subscriptionId"])
    db.collection("payments").document(uid).update({"status": "canceled"})


def construct_webhook_event(payload: bytes, sig_header: str):
    return stripe.Webhook.construct_event(payload, sig_header, _settings.stripe_webhook_secret)


def handle_payment_succeeded(event_data: dict) -> None:
    """Called from the webhook route on `payment_intent.succeeded` /
    `invoice.paid` — flips the user to premium in Firestore."""
    uid = event_data.get("metadata", {}).get("firebaseUid")
    if not uid:
        return

    db = get_firestore_client()
    db.collection("users").document(uid).update({"isPremium": True, "role": "premium_user"})
    db.collection("payments").document(uid).update({"status": "active"})
