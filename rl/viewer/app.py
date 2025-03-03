import os
from flask import Flask, render_template, send_from_directory, abort
import sqlite3
from datetime import datetime
import pytz
import pandas as pd
from pathlib import Path

app = Flask(__name__)

def require_env(env: str) -> str:
    val = os.getenv(env)
    if val is None:
        raise RuntimeError(f"Need environment varaible {env}")
    return val

# Get paths from environment variables with fallbacks
DB_PATH: str = require_env('DB_PATH')
ALTI_HOME: str = require_env('ALTI_HOME')

@app.route('/')
def index():
    # Connect to DuckDB database
    conn = sqlite3.connect(DB_PATH)

    # Get totals first
    totals = pd.read_sql("""
        SELECT
            COUNT(*) as total_replays,
            SUM(duration) / 30.0 as total_seconds
        FROM replays
    """, conn).iloc[0]

    total_replays = totals['total_replays']
    total_duration = totals['total_seconds']
    total_hours = int(total_duration // 3600)
    total_minutes = int((total_duration % 3600) // 60)

    df = pd.read_sql("""
        SELECT * FROM replays
        ORDER BY started_at DESC;
        """, conn)

    df['duration_seconds'] = df['duration'] / 30
    df['duration'] = df['duration_seconds'].apply(lambda x:
        f"{int(x // 60)}:{int(x % 60):02d}"
    )

    # Convert UTC timestamps to local time
    local_tz = datetime.now().astimezone().tzinfo
    df['datetime'] = df['started_at'].apply(lambda x: (
        datetime
        .fromisoformat(str(x))
        .replace(tzinfo=pytz.UTC)
        .astimezone(local_tz)
        .strftime('%Y-%m-%d %H:%M:%S')
        if pd.notna(x) else 'Unknown'
    ))

    replays = df.to_dict('records')

    conn.close()

    return render_template(
        'index.html',
        replays=replays,
        total_replays=total_replays,
        total_hours=total_hours,
        total_minutes=total_minutes
    )

@app.route('/view')
def view_replay():
    return render_template('viewer.html')

@app.route('/viewer.js')
def viewer_js():
    return send_from_directory('js', 'viewer.js')

@app.route('/recordings/<path:filename>')
def recordings(filename):
    try:
        return send_from_directory(Path(ALTI_HOME) / "recordings", filename)
    except FileNotFoundError:
        abort(404)

if __name__ == '__main__':
    app.run(debug=True)
