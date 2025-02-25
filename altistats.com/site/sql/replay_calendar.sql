SELECT
  TO_CHAR(binned_date, 'YYYY-MM-DD') as date,
  COUNT(*) as count
FROM replays
NATURAL JOIN "4ball_games"
WHERE started_at > NOW() - INTERVAL '3 months'
GROUP BY binned_date
ORDER BY date DESC;
