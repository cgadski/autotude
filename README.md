# Autotude

[Altitude](https://altitudegame.com/) was released in 2009 by Nimbly Games.

This repository is my ongoing attempt to make Altitude a nice environment for reinforcement learning. 

So far, we have a message format that lets us stream the state of a game and a "replay viewer" that reads a sequence of messages from a file and lets us view the playback in a browser.

## `proto/`

`proto/` contains the message format used to serialize game state, game inputs, and geometry of game objects.

I've patched Altitude itself (not fully open source) to serialize game state to a stream of `Update` messages. An `Update` is a screenshot of everything a player can observe on the screen at a given moment in time, besides map geometry.

A replay (extension `.pb.gz`) is just a gzipped sequence of length-delimited `Update` messages.

The bandwidth of a game with 8 players (like 4v4 ball) is around 0.2 mbps, or roughly 100x less than the bandwidth of 720p video.

## `out/polys`

Besides map geometry---which is sent in the first `Update` message when a game begins---the only game-related information not included in a streams of `Updates` are the hitboxes of game objects like planes and projectiles. `out/polys` is a gzipped sequence of length-delimited `Poly` messages (as defined in `proto/poly.proto`) giving the hixboxes of different game objects. This data is read from `poly_src`, an pile of XML files copied from Altitude.

Planes have different hitboxes depending on their "roll." The degrees of roll for which hitboxes are available are irregularly distributed.

## `hx_src/`

`hx_src/` contains a few tools and the replay viewer.

### `hx_src/viewer`

Haxe source for a replay viewer. Graphics are drawn using the Heaps game engine.

### `site_src`

Source files for a static website that acts as a replay browser and viewer.

# Makefile targets and utilities

## `make site_gen`

Build static webpages where you can view replays. Host with `server.sh`.

## `make copy_gen`

Copy the generated Java source for our protobuf messages into the Altitude source repository located at `ALTI_PATH`.

## `copy_replay.sh`

Copy the last recorded game to `example_recordings/$1.pb.gz`. (First set RECORDING_PATH to your Altitude instalation directory.)

