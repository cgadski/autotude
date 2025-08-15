DROP TABLE IF EXISTS handles;
CREATE TABLE handles (
    handle_key INTEGER PRIMARY KEY,
    handle,
    automatic
);

CREATE INDEX IF NOT EXISTS idx_handles_handle ON handles (handle);

DROP TABLE IF EXISTS vapor_handle;
CREATE TABLE vapor_handle (
    vapor TEXT PRIMARY KEY,
    handle_key REFERENCES handles (handle_key)
);

CREATE INDEX IF NOT EXISTS idx_vapor_handle_handle ON vapor_handle (handle_key);

DROP VIEW IF EXISTS handles_tbl;
CREATE VIEW handles_tbl
AS SELECT
    ranked_nicks.vapor AS vapor,
    coalesce(custom_handles.handle, '_' || ranked_nicks.nick)
    AS handle,
    custom_handles.handle IS NULL AS automatic
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

INSERT INTO handles (handle, automatic)
SELECT handle, automatic FROM handles_tbl
GROUP BY handle
ORDER BY automatic, handle;

INSERT INTO vapor_handle
SELECT vapor, handle_key
FROM handles_tbl
NATURAL JOIN handles;
