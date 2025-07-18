CREATE OR REPLACE VIEW replays AS
    SELECT DISTINCT ON (stem) *,
        date_trunc('day',
            (started_at::timestamp + interval '12 hours') AT TIME ZONE 'UTC'
        )::date AS binned_date
    FROM replays_raw
    WHERE completed
    ORDER BY stem, replay_key DESC;

DROP MATERIALIZED VIEW IF EXISTS "4ball_games" CASCADE;
CREATE MATERIALIZED VIEW "4ball_games" AS
WITH
active_players AS (
    SELECT replay_key, COUNT(*) AS n_players
    FROM replays r
    NATURAL JOIN players p
    WHERE team > 2
    GROUP BY replay_key
),
no_bots AS (
    SELECT replay_key FROM replays r
    WHERE NOT EXISTS (
        SELECT 1 FROM players p
        WHERE p.replay_key = r.replay_key
        AND p.nick LIKE 'Bot %'
    )
)
SELECT replay_key FROM replays
NATURAL JOIN active_players
NATURAL JOIN no_bots
WHERE map != 'lobby_4ball'
AND n_players = 8;

CREATE VIEW games_per_player AS
SELECT vapor,
COUNT(*) FILTER (WHERE team > 2) as games
FROM players
NATURAL JOIN "4ball_games"
GROUP BY vapor;

DROP MATERIALIZED VIEW IF EXISTS "mv_totals" CASCADE;
CREATE MATERIALIZED VIEW mv_totals AS
WITH
vapor_totals AS (
    SELECT count(distinct vapor) AS n_vapors
    FROM games_per_player
    WHERE games > 0
),
replay_totals AS (
    SELECT count(*) AS n_replays,
    round(sum(duration)::float / 30 / 60 / 60) AS hours
    FROM replays
    NATURAL JOIN "4ball_games"
)
SELECT *
FROM vapor_totals
CROSS JOIN replay_totals;

DROP MATERIALIZED VIEW IF EXISTS "teams" CASCADE;
CREATE MATERIALIZED VIEW teams AS
SELECT
    replay_key,
    jsonb_object_agg(team, player_array) as teams
FROM (
    SELECT replay_key, team, array_agg(
        jsonb_build_object('nick', nick, 'vapor', vapor)
        ORDER BY nick
    ) as player_array
    FROM replays
    NATURAL JOIN players
    GROUP BY replay_key, team
) t
GROUP BY replay_key;

CREATE INDEX IF NOT EXISTS idx_teams_key ON teams (replay_key);
