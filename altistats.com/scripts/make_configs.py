#!/usr/bin/env -S uv run --script
# /// script
# dependencies = [
#   "pystache",
# ]
# ///

import csv, pystache
from pathlib import Path

read_csv = lambda f: list(csv.reader(open(f)))
servers = read_csv("conf/servers.csv")
creds = [{"email": cred[0], "accountPassword": cred[1]} for cred in read_csv("conf/bot_creds.csv")]
spectate_conf = open("conf/spectate_ladder.xml").read()
listing_conf = open("conf/spectate_listings.xml").read()

(Path("build") / "client_configs").mkdir(parents=True, exist_ok=True)

def write_config(path, template, context):
    (Path("build") / "client_configs" / path).write_text(
        pystache.render(template, context)
    )

port = 27285

write_config("spectate_listings.xml", listing_conf, {
    "port": port,
    **creds.pop()
})

port += 1

for i, (server, cred) in enumerate(zip(servers, creds), 1):
    write_config(f"spectate_ladder_{i}.xml", spectate_conf, {
        "port": port,
        "server": server[0],
        "password": server[1] if len(server) > 1 else "",
        **cred
    })

    port += 1
