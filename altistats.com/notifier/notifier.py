#!/usr/bin/env python3
"""Poll events.sql and push each new event to an ntfy topic."""

import json
import os
import time
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path

import psycopg

QUERY = (Path(__file__).parent / "events.sql").read_text()
NTFY_URL = os.environ.get("NTFY_URL", "https://ntfy.sh")
NTFY_TOPIC = os.environ["NTFY_TOPIC"]
STATE_FILE = Path(os.environ.get("STATE_FILE", "/app/state/sent.json"))
POLL_INTERVAL = int(os.environ.get("POLL_INTERVAL", "20"))
CLICK_URL = os.environ.get("CLICK_URL", "http://altistats.com")

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


def load_sent():
    """Returns {(time_iso, name): sent_at_iso}, or None if no state exists yet."""
    if not STATE_FILE.exists():
        return None
    return {(t, n): s for t, n, s in json.loads(STATE_FILE.read_text())}


def save_sent(sent):
    # Events older than the query window can never reappear, so drop them.
    cutoff = (datetime.now(timezone.utc) - timedelta(hours=26)).isoformat()
    rows = [[t, n, s] for (t, n), s in sent.items() if t >= cutoff]
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    tmp = STATE_FILE.with_suffix(".tmp")
    tmp.write_text(json.dumps(rows))
    tmp.replace(STATE_FILE)


def fetch_events():
    with psycopg.connect(CONNINFO) as conn:
        rows = conn.execute(QUERY).fetchall()
    return [
        {"key": (t.astimezone(timezone.utc).isoformat(), name), "name": name,
         "players": players, "map": map_}
        for t, name, players, map_ in rows
    ]


def notify(event):
    plural = "player" if event["players"] == 1 else "players"
    body = json.dumps({
        "topic": NTFY_TOPIC,
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


def tick(sent):
    events = fetch_events()
    now = datetime.now(timezone.utc).isoformat()

    if sent is None:
        # First run: don't flood the phone with the last 24h of history.
        log(f"no state file; marking {len(events)} existing events as sent")
        sent = {e["key"]: now for e in events}
        save_sent(sent)
        return sent

    for e in events:
        if e["key"] in sent:
            continue
        notify(e)
        log(f"sent: {e['key'][0]} {e['name']!r} {e['players']} {e['map']}")
        sent[e["key"]] = now
        save_sent(sent)
    return sent


def main():
    log(f"starting; topic={NTFY_TOPIC[:3]}..., interval={POLL_INTERVAL}s")
    sent = load_sent()
    while True:
        try:
            sent = tick(sent)
        except Exception as exc:
            log(f"error: {exc!r}")
        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    main()
