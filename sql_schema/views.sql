DROP VIEW IF EXISTS replays;
CREATE VIEW replays AS
    SELECT DISTINCT ON (stem) * FROM replays_raw
    WHERE completed
    ORDER BY stem, replay_key DESC;

DROP VIEW IF EXISTS teams;
CREATE VIEW teams AS
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

DROP VIEW IF EXISTS "4ball_games";
CREATE VIEW "4ball_games" AS
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
SELECT stem FROM replays
NATURAL JOIN active_players
NATURAL JOIN no_bots
WHERE map != 'lobby_4ball'
AND n_players = 8;
