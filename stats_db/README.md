# stats database


`bin/dump.rs` defines a Rust app that takes a directory of altitude replay files (at `$REPLAY_DIR`) and dumps a bunch of data into a sqlite database. The tables populated by `dump` are defined in `schema.sql`.

The csv files in `csv` define tables to be loaded into the database verbatim. `csv/broken_replays.csv` defines a list of broken replays that we should not try to read, and should be loaded before running `dump.`

Once the csv tables are loaded and `dump` has populated the tables defined in `schema.sql`, the scripts in `tables/` compute some additional tables.

Some views are defined in `views/`. Per-player statistics are defined in `stats/` and pre-computed by `materialize_stats.py`.
