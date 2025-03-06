# Autotude

[Altitude](https://altitudegame.com/) is a 2d multiplayer game, released in 2009 by Nimbly Games.

This repository is my ongoing attempt to make Altitude a nice environment for reinforcement learning in my (super limited) free time.

So far, we have:

- `proto/`: A protobuf schema that can stream game state at around 12 kbps (raw) or 3 kbps (gzipped).
- `rust_src/`: Various tools to extract features from replay files.
- `hx_src/`: An in-browser replay viewer.
- A headless Altitude client that can connect to online servers and stream game state/accept controls from an external process.
- `altistats.com/`: An [online database](http://altistats.com) of human replays, recorded using the headless client.
- A "bot server" that can plays externally-controlled bots against each other at faster than realtime. (With two bots on a large map, the game can run at least 8 minutes of gameplay per realtime second.)
- `rl/`: A `gymnasium` style environment for controlling the bot server.

# Quickstart

## Dependencies

Install [direnv](https://direnv.net/) to load environment variables from `.envrc` and `rl/.envrc`. Install [just](https://github.com/casey/just) to run commands from `Justfiles`. We also need rust/cargo installed (try https://rustup.rs/) to build a program that processes replay files.

Run `just nix` to build `etc/nix.env` if you'd like to manage Haxe, Java and protoc through nix. These dependencies are not required to do reinforcement learning!

Run `just setup` to download game resources and a build of the in-browser replay viewer (`hx_src/out/viewer.js`) to your working tree.

## Using RL environment

Change directories to `rl`. Run `just benchmark` to run the bot server with no controller attached. It should run and generate replays in `alti_home/replays/`.

Still inside `rl`, run `just index` to build an indexer and index your generated replays. With [uv](https://github.com/astral-sh/uv) installed, run `just view` to run a server that lets you view replays in your browser.

Finally, to run notebooks in `rl/notebooks`, change directories to `rl/notebooks` and run `uv sync` to create a virtualenv. Then try running e.g. `uv run show_random_trajectories.py`.

# Project Structure

## `java_src`

Source for some extra targets

## `altistats.com/`

Source altistats.com, including docker compose files.

- `altistats.com/site`: sveltekit source
- `altistats.com/sql`: database schemas/views for the replay database

## `proto/`

Protobuf message format used to serialize game state, game inputs, and geometry of game objects.

I've patched Altitude (not fully open source) to serialize game state to a stream of `Update` messages. An `Update` is roughly a screenshot of _all_ game-relevant state at a given moment in time besides map geometry. This ncludes information not normally available to a player like positions of off-screen planes, powerups held by enemies, and exact health/energy values of all planes.

Once gzipped, streaming a game as a series of `Update` messages (see `proto/update.proto`) is roughly as efficient as the netcode used by the game but much less arcane. Most importantly, `Updates` don't require the reader to simulate any parts of the game.

A replay (extension `.pb`) is just a gzipped sequence of length-delimited `Update` messages.

The bandwidth of a game with 8 players (like 4v4 ball) tends to be about 0.2 megabytes per minute after gzipping, or roughly 100x less than the bandwidth of 720p video.

## `data/polys`

Map geometry is sent in the first `Update` message when a game begins. Besides map geometry, the only additional information needed to interpret an `Update` are the relative hitboxes of game objects like planes and projectiles. `data/polys` is a gzipped sequence of length-delimited `Poly` messages (as defined in `proto/poly.proto`) giving the hixboxes of different game objects. This data is read from `poly_src`, an bunch of XML files copied from Altitude.

Planes have different hitboxes depending on their "roll." The degrees of roll for which hitboxes are available are irregularly distributed.

## `hx_src/`

Haxe soure. Mainly the replay viewer, written with the heaps game engine.

## `rust_src/`

Rust source for the indexers (`bin/index`, `bin/index-lite`).
