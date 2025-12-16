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
creds = read_csv("conf/bot_creds.csv")
template = open("client_config.xml").read()

(Path("build") / "client_configs").mkdir(parents=True, exist_ok=True)

port = 27285

for i, (server, cred) in enumerate(zip(servers, creds), 1):
    context = {
        "port": port,
        "server": server[0],
        "password": server[1] if len(server) > 1 else "",
        "email": cred[0],
        "accountPassword": cred[1]
    }

    port += 1

    (Path("build") / "client_configs" / f"spectate_ladder_{i}.xml").write_text(
        pystache.render(template, context)
    )
