DROP TABLE IF EXISTS handle_nicks;
CREATE TABLE handle_nicks (
    handle_key INTEGER PRIMARY KEY REFERENCES handles (handle_key),
    nicks
);

INSERT INTO handle_nicks
SELECT
    handle_key,
    json_group_array(DISTINCT nick) AS nicks
FROM players_wide
GROUP BY handle_key;
