SQLITE := sqlite3 $(STATS_DB)

.PHONY: csvs dump views stats

all: $(STATS_DB) \
	views \
	csvs \
	dump \
	stats

$(STATS_DB):
	$(SQLITE) < schema.sql

views:
	@echo "loading views..."
	@$(SQLITE) < views/game_teams.sql
	@$(SQLITE) < views/last_played.sql
	@$(SQLITE) < views/monthly_activity.sql
	@echo "  ...done"

csvs:
	@echo "loading csv tables..."
	@$(SQLITE) "DROP TABLE IF EXISTS custom_handles; CREATE TABLE custom_handles (vapor TEXT, handle TEXT);"
	@$(SQLITE) ".mode csv" ".import csv/custom_handles.csv custom_handles"

	@$(SQLITE) "DROP TABLE IF EXISTS perk_names; CREATE TABLE perk_names (id INTEGER, name TEXT);"
	@$(SQLITE) ".mode csv" ".import csv/perk_names.csv perk_names"

	@$(SQLITE) "DROP TABLE IF EXISTS plane_names; CREATE TABLE plane_names (id INTEGER, name TEXT);"
	@$(SQLITE) ".mode csv" ".import csv/plane_names.csv plane_names"

	@$(SQLITE) "DROP TABLE IF EXISTS broken_replays; CREATE TABLE broken_replays (stem TEXT);"
	@$(SQLITE) ".mode csv" ".import csv/broken_replays.csv broken_replays"

	@$(SQLITE) "DROP TABLE IF EXISTS stat_order; CREATE TABLE stat_order (query_name TEXT);"
	@$(SQLITE) ".mode csv" ".import csv/stat_order.csv stat_order"
	@echo "  ...done"

dump:
	dump --db $(STATS_DB)
	$(SQLITE) < tables/vapors.sql
	$(SQLITE) < tables/handles.sql
	$(SQLITE) < tables/replays_wide.sql
	$(SQLITE) < tables/ladder_games.sql
	$(SQLITE) < tables/players_wide.sql
	$(SQLITE) < tables/players_short.sql
	$(SQLITE) < tables/time_alive.sql

stats:
	python3 materialize_stats.py --db $(STATS_DB) --stats-dir stats/
