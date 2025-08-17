SELECT handle, nicks, last_played,
        datetime('now') >= datetime(last_played, 'unixepoch', '+48 hours') as is_older
FROM last_played
NATURAL JOIN handle_nicks
NATURAL JOIN handles
ORDER BY last_played DESC
