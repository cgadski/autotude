# deployment guide

Get a server with docker compose v2 set up. (I used the Docker on Ubuntu 22.04 image on digitalocean).

First, populate `alti_home/` with `just upload-home`. This copies resources needed for bot clients and replays that you have saved in `$REPLAY_DIR`.

Next, pull images and upload the bot client configs with `just pull`, and upload build + upload viewer resources with `just upload-viewer`.

If you want to save the stats builder from rebuilding `stats.db`, run `just reset-stats` to send your local copy. We also need to run this when we make a big change to the `stats_db` process.

Finally `just up-build` to build and run the Docker compose spec in `prod.yml`.
