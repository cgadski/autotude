DROP TABLE IF EXISTS time_bin_desc;
CREATE TABLE time_bin_desc (
    time_bin INTEGER PRIMARY KEY,
    time_bin_desc TEXT UNIQUE
);

INSERT INTO time_bin_desc (time_bin_desc)
SELECT DISTINCT strftime("%Y-%m", started_at, 'unixepoch')
FROM replays
ORDER BY started_at;

DROP TABLE IF EXISTS time_bins;
CREATE TABLE time_bins (
    replay_key INTEGER PRIMARY KEY REFERENCES replays (replay_key),
    time_bin REFERENCES time_bin_desc (time_bin)
);

INSERT INTO time_bins
SELECT
    replay_key,
    time_bin
FROM replays
JOIN time_bin_desc
ON time_bin_desc = strftime('%Y-%m', started_at, 'unixepoch');
