import os
from redis import Redis
from rq import Connection, Worker

QUEUE_NAME = os.getenv("RQ_QUEUE_NAME", "gtm")
REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379/0")

listen = [QUEUE_NAME]

if __name__ == "__main__":
    redis = Redis.from_url(REDIS_URL)
    with Connection(redis):
        worker = Worker(listen)
        worker.work(with_scheduler=True)