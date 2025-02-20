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
