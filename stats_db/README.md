# stats database

`bin/dump.rs` defines a Rust app that dumps a whole bunch of statistics from a directory of altitude replay files into an sqlite database with schema specified by `schema.sql`. After setting `$REPLAY_DIR`, you can run `just dump` to set up a table and run `dump.rs`. This doesn't process replays which are already processed, and ignores some broken replays defined in `csv/broken_replays.csv`.

`views/` defines a bunch of basic views and tables in this database, and `stats/` defines a bunch of statistics that we display on [http://altistats.com]. Each file in `stats/` starts with a comment giving the statistic a display name, and a prefix that specifies if it's a single number (`_`), a per-player statistic (`p_`), a statistic per game per team (`gt_`), per game per player (`gp_`), etc.

The `Dockerfile` defines a container that I run on the server to periodically sync the stats database with the recording directory.
