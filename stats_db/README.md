# stats database

`bin/dump.rs` defines a Rust app that dumps a whole bunch of statistics from a directory of altitude replay files into an sqlite database with schema specified by `schema.sql`. After setting `$REPLAY_DIR`, you can run `just dump` to set up a table and run `dump.rs`. This doesn't process replays which are already processed, and ignores some broken replays defined in `csv/broken_replays.csv`.

`views/` defines a bunch of basic views and tables in this database, and `stats/` defines a bunch of statistics that we display on [http://altistats.com].

The `Dockerfile` defines a container that I run on the server to periodically sync the stats database with the recording directory.

## stats

When I say a stat is binned over (x?, y), that means it gives a value for every pair (x, y) and x can be null.

Front page stats are just the numbers displayed on the front page.

- `_avg_duration`
- `_games`
- `_goals`
- `_kills`
- `_messages`
- `_players`
- `_time`

Historical stats are binned over month?.

- `h_games`
- `h_time`
- `h_players`

Historical player stats are binned over (player, month?):

- `hp_games`
- `hp_time`

Player stats are binned over (player, month?, plane?):
