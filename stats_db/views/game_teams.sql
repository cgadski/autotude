DROP VIEW IF EXISTS game_teams;
CREATE VIEW game_teams AS
WITH team_players AS (
    SELECT
        replay_key,
        team,
        json_group_array(
            handle
        ) AS players_json
    FROM (
        SELECT DISTINCT
            replay_key,
            team,
            handle
        FROM players_wide
        NATURAL JOIN handles
        ORDER BY handle
    )
    GROUP BY replay_key, team
)
SELECT
    replay_key,
    json_group_object(team, json(players_json)) AS teams
FROM team_players
GROUP BY replay_key;
