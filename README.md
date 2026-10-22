# Autotude

[Altitude](https://altitudegame.com/) is a 2d multiplayer game, released in 2009 by Nimbly Games.

This repository is my ongoing attempt to make Altitude a nice environment for reinforcement learning in my (super limited) free time + do some other nice stuff.

On the RL side, we have:

- `proto/`: A protobuf schema that can stream game state at around 12 kbps (raw) or 3 kbps (gzipped).
- A "bot server" that can plays externally-controlled bots against each other at faster than realtime. (With two bots on a large map, the game can run at least 8 minutes of gameplay per realtime second.)
- `rl/`: A `gymnasium` style environment for controlling the bot server + some ongoing experiments on reinforcement learning.
- A headless Altitude client that can connect to online servers and stream game state/accept controls from an external process.

On the nice stuff side:

- `altistats.com/`: An [online database](http://altistats.com) of games played on Van1shing's 4ball servers.
- `stats_db/`: Tools to index human replays and wrangle data, used by the site.
- `viewer/`: An in-browser replay viewer hosted on the site.

# Quickstart for RL

## Dependencies

Install [direnv](https://direnv.net/) to load environment variables from `.envrc` and `rl/.envrc`. Install [just](https://github.com/casey/just) to run commands from `Justfiles`.

Run `just nix` to build `etc/nix.env` if you'd like to manage Haxe, Java and protoc through nix. These dependencies are not required for RL.

Run `just setup` to download resources (bot server, `alti_home/` contents) needed for RL.

## Using RL environment

Change directories to `rl`. Run `just benchmark` to run the bot server with no controller attached. It should run and generate replays in `alti_home/replays/`.

With rust/cargo installed (try `https://rustup.rs/`), run `just index` to build an indexer and index your generated replays in `DB_PATH`. With [uv](https://github.com/astral-sh/uv) installed, run `just view` to run a server that lets you view replays in your browser.

Finally, to run notebooks in `rl/notebooks`, change directories to `rl/notebooks` and run `uv sync` to create a virtualenv. Try running `uv run show_random_trajectories.py`.

# Project Structure

## `altistats.com/`

Source altistats.com, including docker compose files.

- `altistats.com/site`: sveltekit source
- `altistats.com/prod.yml`: docker compile file for the whole operation (listing bot, replay bots, website, replay indexer/stat counter)

## `proto/`

Protobuf message format used to serialize game state, game inputs, and geometry of game objects.

I've patched Altitude (not fully open source) to serialize game state to a stream of `Update` messages. An `Update` is roughly a screenshot of _all_ game-relevant state at a given moment in time besides map geometry. This ncludes information not normally available to a player like positions of off-screen planes, powerups held by enemies, and exact health/energy values of all planes.

Once gzipped, streaming a game as a series of `Update` messages (see `proto/update.proto`) is roughly as efficient as the netcode used by the game but much less arcane. Most importantly, `Updates` don't require the reader to simulate any parts of the game.

A replay (extension `.pb`) is just a gzipped sequence of length-delimited `Update` messages.

The bandwidth of a game with 8 players (like 4v4 ball) tends to be about 0.2 megabytes per minute after gzipping, or roughly 100x less than the bandwidth of 720p video.

## `viewer/`

Replay viewer, written in haxe with the heaps game library. Requires resources from the game. Test it out with `just view $STEM`.

## `game_resources/`

Rust tools that extract sprites, hitboxes, sounds, and map data from altitude for use in the replay viewer. Set `ALTI_INSTALL` and `ALTI_MAP_PATH` (colon-separated) and run `make game_resources`. 

- `out/sprites`: game assets as `.pngs` + `sprites.json`, 11M
- `out/sounds`: sounds, 2.4M
- `out/`: map data + graphics, about 1M per map

## `stats_db/`

Some Rust tools for inspecting replays/dumping some of their data to a sqlite database + a bunch of sql that wrangles this data into tables used on `altistats.com`. The `Dockerfile` defines a service that periodically reads replays written by the bot clients and writes to the sqlite database. More information on `stats_db/README.md`.
