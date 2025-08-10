from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import os
from redis import Redis
from rq import Queue

from worker_tasks import process_referral_join, check_subscriptions_and_award

app = FastAPI(title="GTM Referrals Service")

REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379/0")
QUEUE_NAME = os.getenv("RQ_QUEUE_NAME", "gtm")

redis = Redis.from_url(REDIS_URL)
queue = Queue(QUEUE_NAME, connection=redis, default_timeout=120)

class ReferralJoinIn(BaseModel):
    referral_code: str
    referred_telegram_id: int

class CheckSubsIn(BaseModel):
    telegram_id: int

class DirectUpdateIn(BaseModel):
    telegram_id: int
    # Optional deltas or absolute values; if both provided, deltas take precedence
    inc_referral_tickets: int | None = None
    inc_subscription_tickets: int | None = None
    set_invited_by_referral_code: str | None = None
    set_invited_by_user_id: int | None = None

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/enqueue/referral-join")
def enqueue_referral_join(body: ReferralJoinIn):
    if not body.referral_code or not body.referred_telegram_id:
        raise HTTPException(status_code=400, detail="referral_code and referred_telegram_id required")
    job = queue.enqueue(process_referral_join, body.referral_code, int(body.referred_telegram_id))
    return {"enqueued": True, "job_id": job.id}

@app.post("/enqueue/check-subscriptions")
def enqueue_check_subscriptions(body: CheckSubsIn):
    if not body.telegram_id:
        raise HTTPException(status_code=400, detail="telegram_id required")
    job = queue.enqueue(check_subscriptions_and_award, int(body.telegram_id))
    return {"enqueued": True, "job_id": job.id}

# Synchronous endpoints
@app.post("/check-subscriptions")
def check_subscriptions(body: CheckSubsIn):
    if not body.telegram_id:
        raise HTTPException(status_code=400, detail="telegram_id required")
    return check_subscriptions_and_award(int(body.telegram_id))


@app.post("/referral-join")
def referral_join(body: ReferralJoinIn):
    if not body.referral_code or not body.referred_telegram_id:
        raise HTTPException(status_code=400, detail="referral_code and referred_telegram_id required")
    return process_referral_join(body.referral_code, int(body.referred_telegram_id))

# Optional: direct update endpoint if another service already did the checks
# It enqueues a tiny job that fetches current counters and updates users coherently
@app.post("/enqueue/direct-update")
def enqueue_direct_update(body: DirectUpdateIn):
    from worker_tasks import direct_update_user_counters  # lazy import
    job = queue.enqueue(direct_update_user_counters, body.dict())
    return {"enqueued": True, "job_id": job.id}