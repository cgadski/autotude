CREATE TABLE IF NOT EXISTS time_bin_desc (
    time_bin INTEGER PRIMARY KEY,
    time_bin_desc TEXT UNIQUE
);

INSERT OR IGNORE INTO time_bin_desc (time_bin_desc)
SELECT DISTINCT strftime("%Y-%m", started_at, 'unixepoch')
FROM replays
ORDER BY started_at;

-- bunch of features computed for each game
CREATE TABLE IF NOT EXISTS replays_wide (
    replay_key INTEGER PRIMARY KEY REFERENCES replays (replay_key),
    time_bin, -- time bin this replay belongs to
    day_bin TEXT, -- day bin where each "day" starts at noon UTC
    n_left, -- number of players on each team
    n_right,
    n_spec,
    n_goals,
    start_messages, -- server message counts
    stop_messages,
    restart_messages,
    player_messages,
    next_key, -- next replay on same server
    prev_key, -- previous replay on same server
    winner -- last team that scored
);

CREATE TEMP TABLE replays_fresh AS
SELECT r.*
FROM replays r
LEFT JOIN replays_wide rw USING (replay_key)
WHERE (
    rw.replay_key is null
    OR rw.next_key is null
    AND server != ''
);

INSERT OR REPLACE INTO replays_wide
WITH
time_bin AS (
    SELECT
        replay_key,
        time_bin
    FROM replays_fresh
    JOIN time_bin_desc
    ON time_bin_desc = strftime('%Y-%m', started_at, 'unixepoch')
),
consecutive AS (
	SELECT
		replay_key,
		lead(replay_key, 1)
		OVER (PARTITION BY server ORDER BY started_at) AS next
	FROM replays
),
stop_messages AS (
    SELECT
        replay_key,
        count() AS stop_messages
    FROM replays_fresh NATURAL JOIN messages
    WHERE player_key IS NULL
    AND (chat_message = 'Players agreed to stop game.'
    OR chat_message LIKE 'Game stopped by %')
    GROUP BY replay_key
),
start_messages AS (
    SELECT
        replay_key,
        count() AS start_messages
    FROM replays_fresh NATURAL JOIN messages
    WHERE player_key IS NULL
    AND chat_message LIKE 'Start Ranked vote passed with %'
    GROUP BY replay_key
),
restart_messages AS (
    SELECT
        replay_key,
        count() AS restart_messages
    FROM replays_fresh NATURAL JOIN messages
    WHERE player_key IS NULL
    AND chat_message = 'Game has been restarted.'
    GROUP BY replay_key
),
player_messages AS (
    SELECT
        replay_key,
        count() AS player_messages
    FROM replays_fresh NATURAL JOIN messages
    WHERE player_key IS NOT NULL
    GROUP BY replay_key
),
n_players AS (
    SELECT
        replay_key,
        count(DISTINCT VAPOR) FILTER (WHERE team = 3) AS n_left,
        count(DISTINCT VAPOR) FILTER (WHERE team = 4) AS n_right,
        count(DISTINCT VAPOR) FILTER (WHERE team = 2) AS n_spec
    FROM replays_fresh
    NATURAL JOIN players
    GROUP BY replay_key
),
n_goals AS (
    SELECT
        replay_key,
        count() FILTER (WHERE player_key IS NOT NULL) AS n_goals
    FROM replays_fresh
    LEFT JOIN goals USING (replay_key)
    GROUP BY replay_key
),
winner AS (
    SELECT
        replay_key,
        team as winner
    FROM (
        SELECT
            replay_key,
            team,
            row_number() OVER (
                PARTITION BY replay_key ORDER BY tick DESC
            ) AS goal_idx
        FROM replays_fresh
        NATURAL JOIN goals
    )
    WHERE goal_idx = 1
)
SELECT
    r.replay_key,
    time_bin,
    date(datetime(r.started_at, 'unixepoch'), '-12 hours', 'utc') as day_bin,
    coalesce(n_left, 0),
    coalesce(n_right, 0),
    coalesce(n_spec, 0),
    n_goals,
    coalesce(start_messages, 0) AS start_messages,
    coalesce(stop_messages, 0) AS stop_messages,
    coalesce(restart_messages, 0) AS restart_messages,
    coalesce(player_messages, 0) AS player_messages,
    a.next AS next_key,
    b.replay_key AS prev_key,
    winner
FROM replays_fresh r
NATURAL JOIN time_bin
NATURAL LEFT JOIN n_players
NATURAL JOIN n_goals
NATURAL LEFT JOIN start_messages
NATURAL LEFT JOIN stop_messages
NATURAL LEFT JOIN restart_messages
NATURAL LEFT JOIN player_messages
LEFT JOIN consecutive a ON (r.replay_key = a.replay_key)
LEFT JOIN consecutive b ON (r.replay_key = b.next)
NATURAL LEFT JOIN winner;
