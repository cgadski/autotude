DROP TABLE IF EXISTS names;
CREATE TABLE names (
    vapor PRIMARY KEY,
    name
);

INSERT INTO names
SELECT
    ranked_nicks.vapor AS vapor,
    coalesce(named_players.name, ranked_nicks.nick) AS name
FROM named_players
RIGHT JOIN (
	SELECT
		vapor,
		nick,
		nick_count,
		row_number() OVER (
			PARTITION BY vapor
			ORDER BY nick_count desc
		) AS rank
	FROM (
		SELECT vapor, nick, count(*) AS nick_count
		FROM players
		GROUP BY vapor, nick
	)
	ORDER BY vapor, rank
) AS ranked_nicks
	ON named_players.vapor = ranked_nicks.vapor
WHERE ranked_nicks.rank = 1
AND ranked_nicks.vapor != '';
