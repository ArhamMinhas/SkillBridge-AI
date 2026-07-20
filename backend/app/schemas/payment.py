from pydantic import BaseModel


class CreateSubscriptionIntentRequest(BaseModel):
    plan: str  # "PRO" (monthly) or "PRO_YEARLY"


class CreateSubscriptionIntentResponse(BaseModel):
    clientSecret: str
    customerId: str
    ephemeralKey: str
    publishableKey: str
