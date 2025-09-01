-- Integer ids for each vapor, for use in players_wide table.
-- (We don't use handle_keys in players_wide so that we don't have to
-- re-compute players_wide after merging handles>
CREATE TABLE IF NOT EXISTS vapors (
    vapor_key INTEGER PRIMARY KEY,
    vapor TEXT
);

CREATE INDEX IF NOT EXISTS idx_vapors_vapor ON vapors (vapor);

INSERT INTO vapors (vapor)
SELECT DISTINCT vapor FROM players
WHERE vapor NOT IN (SELECT vapor FROM vapors);
