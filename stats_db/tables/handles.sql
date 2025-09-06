BEGIN;

-- List of handles and their integer keys
DROP TABLE IF EXISTS handles;
CREATE TABLE handles (
    handle_key INTEGER PRIMARY KEY,
    handle,
    automatic
);
CREATE INDEX IF NOT EXISTS idx_handles_handle ON handles (handle);

-- Map from vapor ids to handles
DROP TABLE IF EXISTS vapor_handle;
CREATE TABLE vapor_handle (
    vapor_key REFERENCES vapors (vapor_key),
    handle_key REFERENCES handles (handle_key)
);
CREATE INDEX IF NOT EXISTS idx_vapor_handle_handle ON vapor_handle (handle_key);

-- Pre-computed list of nicks used by each handle
DROP TABLE IF EXISTS handle_nicks;
CREATE TABLE handle_nicks (
    handle_key INTEGER PRIMARY KEY REFERENCES handles (handle_key),
    nicks JSON
);

-- Shortcut relation from (replay_key, player_key) -> handle_key
DROP TABLE IF EXISTS player_key_handle;
CREATE TABLE player_key_handle (
    replay_key INTEGER REFERENCES replays (replay_key),
    player_key INTEGER,
    handle_key INTEGER REFERENCES handles (handle_key),
    PRIMARY KEY (replay_key, player_key)
);

-- Logic to generate handles for players, either by using their manually
-- specified handle in custom_handles.csv or by taking their most used nickname.
-- A handle is "automatic" in the second case, and gets an underscore prepended
-- to avoid collisions with non-automatic handles.
CREATE TEMP TABLE handles_tbl
AS SELECT
    vapor_key,
    coalesce(custom_handles.handle, '_' || ranked_nicks.nick) AS handle,
    custom_handles.handle IS NULL AS automatic
FROM (
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
LEFT JOIN custom_handles
    ON custom_handles.vapor = ranked_nicks.vapor
JOIN vapors ON (ranked_nicks.vapor = vapors.vapor)
WHERE ranked_nicks.rank = 1
AND ranked_nicks.vapor != '';

SELECT 'Assigned ' || count(DISTINCT handle) || ' handles to ' || count() || ' vapors'
FROM handles_tbl;

INSERT INTO handles (handle, automatic)
SELECT handle, automatic FROM handles_tbl
GROUP BY handle
ORDER BY automatic, handle;

INSERT INTO vapor_handle
SELECT vapor_key, handle_key
FROM handles_tbl
NATURAL JOIN handles;

INSERT INTO player_key_handle
SELECT replay_key, player_key, handle_key
FROM players
JOIN vapors USING (vapor)
JOIN vapor_handle USING (vapor_key);

INSERT INTO handle_nicks
SELECT
    handle_key,
    json_group_array(nick) AS nicks
FROM (
    SELECT DISTINCT handle_key, nick
    FROM players NATURAL JOIN replays
    NATURAL JOIN player_key_handle
    ORDER BY handle_key, started_at DESC
)
GROUP BY handle_key;

COMMIT;
