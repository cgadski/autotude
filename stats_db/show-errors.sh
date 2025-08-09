#!/usr/bin/env bash
set -euo pipefail

if [ ! -f altistats.db ]; then
	echo "Database altistats.db not found"
	exit 1
fi

stems=$(sqlite3 altistats.db "SELECT stem FROM errored ORDER BY stem;")
if [ -z "$stems" ]; then
	echo "No errors found in database"
	exit 0
fi

echo "Errored replays:"
echo "=================="

while IFS= read -r stem; do
	if [ -n "$stem" ]; then
		replay_file="$REPLAY_DIR/${stem}.pb"
		creation_time=$(stat -c %y "$replay_file" 2>/dev/null)
		echo "$stem, $creation_time"
	fi
done <<< "$stems"
