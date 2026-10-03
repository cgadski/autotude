#!/usr/bin/env python3
"""Poll events.sql and push each new event to its ntfy topic."""

import json
import os
import time
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path

import psycopg

QUERY = (Path(__file__).parent / "events.sql").read_text()
NTFY_URL = os.environ.get("NTFY_URL", "http://ntfy")
STATE_FILE = Path(os.environ.get("STATE_FILE", "/app/state/sent.json"))
POLL_INTERVAL = int(os.environ.get("POLL_INTERVAL", "20"))
CLICK_URL = os.environ.get("CLICK_URL", "https://altistats.com")

CONNINFO = " ".join(
    f"{k}={v}"
    for k, v in {
        "host": os.environ.get("POSTGRES_HOST"),
        "port": os.environ.get("POSTGRES_PORT"),
        "user": os.environ.get("POSTGRES_USER"),
        "password": os.environ.get("POSTGRES_PASSWORD"),
        "dbname": os.environ.get("POSTGRES_DB"),
    }.items()
    if v
)


def log(msg):
    print(f"{datetime.now(timezone.utc).isoformat(timespec='seconds')} {msg}", flush=True)


class State:
    """Which events have been sent, and which topics we've seen before.

    An event's key is (time_iso, name, topic).
    """

    def __init__(self, topics=(), sent=None):
        self.topics = set(topics)
        self.sent = dict(sent or {})  # key -> sent_at_iso

    @classmethod
    def load(cls):
        if not STATE_FILE.exists():
            return cls()
        data = json.loads(STATE_FILE.read_text())
        if not isinstance(data, dict):
            # Pre-topics format; start over (existing events get marked as sent).
            log("old state file format; resetting")
            return cls()
        return cls(
            data["topics"],
            {(t, n, topic): s for t, n, topic, s in data["sent"]},
        )

    def save(self):
        # Events older than the query window can never reappear, so drop them.
        cutoff = (datetime.now(timezone.utc) - timedelta(hours=26)).isoformat()
        data = {
            "topics": sorted(self.topics),
            "sent": [[*k, s] for k, s in self.sent.items() if k[0] >= cutoff],
        }
        STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
        tmp = STATE_FILE.with_suffix(".tmp")
        tmp.write_text(json.dumps(data))
        tmp.replace(STATE_FILE)


def fetch_events():
    with psycopg.connect(CONNINFO) as conn:
        rows = conn.execute(QUERY).fetchall()
    return [
        {"key": (t.astimezone(timezone.utc).isoformat(), name, topic),
         "name": name, "players": players, "map": map_, "topic": topic}
        for t, name, players, map_, topic in rows
    ]


def notify(event):
    plural = "player" if event["players"] == 1 else "players"
    body = json.dumps({
        "topic": event["topic"],
        "title": event["name"],
        "message": f"{event['players']} {plural} on {event['map']}",
        "click": CLICK_URL,
        "tags": ["airplane"],
    }).encode()
    req = urllib.request.Request(
        NTFY_URL, data=body, headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        resp.read()


def tick(state):
    events = fetch_events()
    now = datetime.now(timezone.utc).isoformat()

    # Topics we haven't seen before (first run, or a newly added query):
    # mark their old events as sent instead of flooding the phone, but still
    # send anything recent.
    new_topics = {e["topic"] for e in events} - state.topics
    if new_topics:
        recent = (datetime.now(timezone.utc) - timedelta(minutes=5)).isoformat()
        backlog = [e for e in events
                   if e["topic"] in new_topics and e["key"][0] < recent]
        log(f"new topics {sorted(new_topics)}; marking {len(backlog)} existing events as sent")
        for e in backlog:
            state.sent[e["key"]] = now
        state.topics |= new_topics
        state.save()

    for e in events:
        if e["key"] in state.sent:
            continue
        notify(e)
        log(f"sent [{e['topic']}]: {e['key'][0]} {e['name']!r} {e['players']} {e['map']}")
        state.sent[e["key"]] = now
        state.save()


def main():
    log(f"starting; url={NTFY_URL} interval={POLL_INTERVAL}s")
    state = State.load()
    while True:
        try:
            tick(state)
        except Exception as exc:
            log(f"error: {exc!r}")
        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    main()
