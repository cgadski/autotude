from datetime import datetime
import pystache
import sqlite3
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
    return d


replay_context = [make_replay(row) for row in replays]

data = {"replays": replay_context}

with open("site_gen/index.html", "w") as f:
    f.write(pystache.render(template, data))

# create hard links to replay files for each replay in list
for replay in replay_context:
    path = replay['path']
    dst = f"site_gen/recordings/{replay['replay_id']}"
    os.link(path, dst)

conn.close()
