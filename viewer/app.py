import os
from flask import Flask, render_template, send_from_directory, abort
import duckdb
import pandas as pd
from datetime import datetime
import pytz

app = Flask(__name__)

# Get paths from environment variables with fallbacks
DB_PATH = os.getenv('DATA_DIR', 'data') + '/index.db'
RECORDINGS_PATH = os.getenv('ALTI_RECORDINGS', 'recordings')

@app.route('/')
def index():
    # Connect to DuckDB database
    conn = duckdb.connect(DB_PATH, read_only=True)

    # Get totals first
    totals = conn.execute("""
        SELECT 
            COUNT(*) as total_replays,
            SUM(ticks) / 30 as total_seconds
        FROM replays
        WHERE NOT errored
    """).df().iloc[0]
    
    total_replays = totals['total_replays']
    total_duration = totals['total_seconds']
    total_hours = int(total_duration // 3600)
    total_minutes = int((total_duration % 3600) // 60)

    # Query to get replay info as pandas DataFrame
    with open('viewer/sql/replays.sql', 'r') as f:
        query = f.read()
    df = conn.execute(query).df()
    
    # Format duration as MM:SS
    df['duration'] = df['duration_seconds'].apply(lambda x: 
        f"{int(x // 60)}:{int(x % 60):02d}"
    )

    # Convert UTC timestamps to local time
    local_tz = datetime.now().astimezone().tzinfo
    df['datetime'] = df['datetime'].apply(lambda x: (
        datetime
        .fromisoformat(str(x))
        .replace(tzinfo=pytz.UTC)
        .astimezone(local_tz)
        .strftime('%Y-%m-%d %H:%M:%S')
        if pd.notna(x) else 'Unknown'
    ))

    replays = df.to_dict('records')

    conn.close()

    return render_template('index.html', 
                         replays=replays,
                         total_replays=total_replays,
                         total_hours=total_hours,
                         total_minutes=total_minutes)

@app.route('/view')
def view_replay():
    return render_template('viewer.html')

@app.route('/viewer.js')
def viewer_js():
    return send_from_directory('../hx_src/out', 'viewer.js')

@app.route('/recordings/<path:filename>')
def recordings(filename):
    try:
        return send_from_directory(RECORDINGS_PATH, filename)
    except FileNotFoundError:
        abort(404)

if __name__ == '__main__':
    app.run(debug=True)
