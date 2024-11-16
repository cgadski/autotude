from datetime import datetime
from typing import List
import pystache
import sqlite3
import json
import os
import glob
from pathlib import Path
from os import path
from os.path import join


SITE_SRC = "site_src"
SITE_GEN = "site_gen"


class ReplayIndex:
    def __init__(self, sql_path: str):
        self.sql_path = sql_path
        self.filename = Path(sql_path).stem + ".html"

        # Read SQL query
        with open(sql_path) as f:
            self.query = f.read()

        # Read template
        with open(join(SITE_SRC, "index.html")) as f:
            self.template = f.read()

        # Execute query
        conn = sqlite3.connect("replay_index.db")
        cursor = conn.cursor()
        cursor.execute(self.query)
        raw_replays = cursor.fetchall()

        # Process replays
        self.replays = []
        for row in raw_replays:
            d = dict(zip([column[0] for column in cursor.description], row))
            d["time"] = datetime.fromtimestamp(d["time"]).strftime("%Y-%m-%d %H:%M:%S")
            player_array = json.loads(d["players"])
            left_team = min(p[1] for p in player_array)
            d["left_team"] = [p[0] for p in player_array if p[1] == left_team]
            d["right_team"] = [p[0] for p in player_array if p[1] != left_team]
            tot_seconds = int(d["ticks"] / 30)
            seconds = tot_seconds % 60
            minutes = tot_seconds // 60
            d["duration"] = f"{minutes}:{seconds:02d}"
            self.replays.append(d)

        conn.close()

    def write(self, out_path: str):
        context = {"replays": self.replays, "query": self.query}

        with open(out_path, "w") as f:
            f.write(pystache.render(self.template, context))


def write_index(indices: List[ReplayIndex], path: str):
    """Creates an index page that links to all other index pages"""
    index_template = """<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/water.css@2/out/water.css">
    <title>Replay Index</title>
</head>
<body>
    <h1>Replay Collections</h1>
    <ul>
    {{#pages}}
        <li><a href="{{filename}}">{{filename}}</a></li>
    {{/pages}}
    </ul>
</body>
</html>"""

    context = {"pages": [{"filename": index.filename} for index in indices]}

    with open(path, "w") as f:
        f.write(pystache.render(index_template, context))


def main():
    conn = sqlite3.connect("replay_index.db")
    cursor = conn.cursor()

    with open("site_src/index.html", "r") as template_file:
        template = template_file.read()

    os.makedirs(SITE_GEN, exist_ok=True)
    os.makedirs(join(SITE_GEN, "recordings"), exist_ok=True)

    files = glob.glob(join(SITE_SRC, "index/*.sql"))
    indices = [ReplayIndex(path) for path in files]
    all_replays = set()

    for i in indices:
        i.write(join(SITE_GEN, i.filename))
        all_replays.update((r["replay_id"], r["path"]) for r in i.replays)

    write_index(indices, join(SITE_GEN, "index.html"))

    for replay_id, path in all_replays:
        dst = f"site_gen/recordings/{replay_id}"
        try:
            os.link(path, dst)
        except FileExistsError:
            pass  # Skip if link already exists

    conn.close()


if __name__ == "__main__":
    main()
