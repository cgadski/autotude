-- Total data
SELECT printf('%.2fG', sum(bytes)/1000000000.)
FROM replays NATURAL JOIN ladder_games
