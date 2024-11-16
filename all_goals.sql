WITH
ladder_games AS (
    SELECT
        replay_id,
        path,
        COUNT(DISTINCT name) AS n_players,
        (SELECT COUNT() FROM goals g WHERE g.replay_id == replays.replay_id) AS goals,
        ticks / (60 * 30) AS minutes
    FROM replays
    NATURAL JOIN players
    WHERE map LIKE "ball_4%" AND minutes >= 2
    AND NOT EXISTS (SELECT 1
        FROM players p
        WHERE p.replay_id == replays.replay_id
            AND p.name LIKE "Bot%"
    )
    GROUP BY replay_id
    HAVING n_players >= 8 AND goals >= 2
)
SELECT path
FROM (SELECT replay_id FROM ladder_games)
NATURAL JOIN replays
-- SELECT name, COUNT() AS goals
-- FROM (SELECT replay_id FROM ladder_games)
-- NATURAL JOIN goals
-- GROUP BY name
-- ORDER BY goals DESC
