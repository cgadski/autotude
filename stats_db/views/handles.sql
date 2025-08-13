DROP TABLE IF EXISTS handles;
CREATE TABLE handles (
    handle_key INTEGER PRIMARY KEY,
    vapor,
    handle
);

CREATE INDEX idx_handles_vapor ON handles (vapor);
CREATE INDEX idx_handles_handle ON handles (handle);

INSERT INTO handles (vapor, handle)
SELECT
    ranked_nicks.vapor AS vapor,
    coalesce(custom_handles.handle, ranked_nicks.nick) AS handle
FROM custom_handles
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
	ON custom_handles.vapor = ranked_nicks.vapor
WHERE ranked_nicks.rank = 1
AND ranked_nicks.vapor != '';
