# stats database

`bin/dump.rs` defines a Rust app that takes a directory of altitude replay files (at `$REPLAY_DIR`) and dumps a bunch of data into a sqlite database. The tables populated by `dump` are defined in `schema.sql`.

The csv files in `csv` define tables to be loaded into the database verbatim. `csv/broken_replays.csv` defines a list of broken replays that we should not try to read, and should be loaded before running `dump`.

Once the csv tables are loaded and `dump` has populated the tables defined in `schema.sql`, the scripts in `tables/` compute some additional tables.

Some views are defined in `views/`. Per-player statistics are defined in `stats/` and pre-computed by `materialize_stats.py`.

## keys

**replay_key**: Integer primary key for each replay file. Maps to the `replays` table.

**stem**: The filename of the replay without extension (e.g. "ad9b5b21-de93-434a-8735-765576c11047"). Used to identify replay files on disk.

**player_key**: Integer identifier for a player within a specific replay. Multiple players can have the same `player_key` across different replays.

**player_id**: Identifier for players within altitude. These are reused as players join/leave the game, so a single `player_id` can map to different `player_key` within the same replay! The assignment (game tick, player_id) -> player_key is implicitly defined by `IndexingListener`. These don't get stored in the database.

**handle_key**: Integer key for player identities.

## tables/views

### core data (produced by `dump.rs`)

**replays**: One record per replay file.

**players**: One record per interval a player was in a game, including e.g. nick and vapor. Includes spectators, and may include more than one row per player. If a player was ever not a spectator, `team` gives the last non-spectator team to which they assigned.

**spawns**, **kills**, **goals**, **possession**, **messages**, **damage**: Self-explanatory. Players are referenced by (replay_key, player_key).

### computed tables (produced by scripts from `tables/`)

**handles**: Maps `handle_key` to handle strings. Each row is meant to be a player identity. Handles can be manually assigned by `custom_handles.csv`. More than one vapor can be assigned to the same handle.

**vapor_handle**: Maps vapor ids to handle_key.

**player_key_handle**: Maps directly from (replay_key, player_key) to handle_key, to avoid a join with the players table for some queries.

**replays_wide**: Various extra columns computed for each row of `replays`.

**ladder_games**: `replay_keys` that count as ladder games. There's some complexity in detecting ladder games. One issue is that a replay that looks at first like a game might turn out to be cancelled if the next replay on the same server has a "game cancelled" message from the server. So, replays sometimes enter the `ladder_games` table and then get removed.

**players_wide**: Metadata per player per "loadout period", meaning a period when a player was using the same perks. Used for computing a lot of aggregate statistics.

**players_short**: Metadata per player per game.

## stats

**stats/**: Pre-computed statistics (win rate, K/D ratio, goal rate, etc.) evaluated by `materialize_stats.py`. The `stats` view provides metadata on what stats are available, and the `global_stats` and `player_stats` tables hold the computed values. `stat_order.csv` determines the order that stats are displayed in the UI.

The point of the stats system is that I can just add a sql file and have the frontend show a new stat.
