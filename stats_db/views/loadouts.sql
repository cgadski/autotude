-- consecutively grouped loadouts (if two consecutive spawns have the same loadout, they have the same loadout row)

drop view if exists loadouts;
create view loadouts as
with ranked_loadouts as (
	select
		spawns.*,
		row_number() over (partition by replay_key, player_key order by start_tick) as rank_in_player_and_game,
		row_number() over (partition by replay_key, player_key, plane, red_perk, green_perk, blue_perk order by start_tick) as rank_in_player_and_game_and_loadout
	from spawns
	order by replay_key, player_key
)
select
	replay_key,
	player_key,
	plane,
	red_perk,
	green_perk,
	blue_perk,
	min(start_tick) as start_tick,
	max(end_tick) as end_tick,
	sum(end_tick - start_tick) as ticks_alive
from ranked_loadouts
group by
	replay_key,
	player_key,
	plane,
	red_perk,
	green_perk,
	blue_perk,
	rank_in_player_and_game - rank_in_player_and_game_and_loadout;

-- timeline of pretty-printed player loadouts per game
drop view if exists readable_loadouts;
create view readable_loadouts as
select
	loadouts.replay_key,
	player_display_names.name as name,
	plane_names.name as plane,
	red_name.name as red_perk,
	green_name.name as green_perk,
	blue_name.name as blue_perk,
	loadouts.ticks_alive / 30 / 60 as minutes_alive,
	loadouts.ticks_alive,
	loadouts.start_tick,
	loadouts.end_tick,
	player_display_names.vapor,
	replays.stem
from loadouts
inner join players
	on loadouts.player_key = players.player_key and loadouts.replay_key = players.replay_key
inner join player_display_names
	on players.vapor = player_display_names.vapor
inner join replays
	on players.replay_key = replays.replay_key
inner join ladder_games
	on replays.replay_key = ladder_games.replay_key
left join plane_names
	on loadouts.plane = plane_names.id
left join perk_names red_name
	on loadouts.red_perk = red_name.id
left join perk_names green_name
	on loadouts.green_perk = green_name.id
left join perk_names blue_name
	on loadouts.blue_perk = blue_name.id
order by loadouts.replay_key, player_display_names.vapor, start_tick;
