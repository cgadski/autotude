from datetime import datetime
import pystache
import sqlite3
import json
import os

conn = sqlite3.connect("replay_index.db")
cursor = conn.cursor()

with open("site_src/index.sql") as f:
    query = f.read()

cursor.execute(query)

replays = cursor.fetchall()

with open("site_src/index.html", "r") as template_file:
    template = template_file.read()


def make_replay(row):
    d = dict(zip([column[0] for column in cursor.description], row))
    d["time"] = datetime.fromtimestamp(d["time"]).strftime("%Y-%m-%d %H:%M:%S")
    player_array = json.loads(d["players"])
    left_team = min(p[1] for p in player_array)
    d["left_team"] = [p[0] for p in player_array if p[1] == left_team]
    d["right_team"] = [p[0] for p in player_array if p[1] != left_team]
    return d


replay_context = [make_replay(row) for row in replays]

context = {
    "replays": replay_context,
    "query": query
}

with open("site_gen/index.html", "w") as f:
    f.write(pystache.render(template, context))

# create hard links to replay files for each replay in list
for replay in replay_context:
    path = replay['path']
    dst = f"site_gen/recordings/{replay['replay_id']}"
    os.link(path, dst)

conn.close()
