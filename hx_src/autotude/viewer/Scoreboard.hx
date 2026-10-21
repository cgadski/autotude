package autotude.viewer;

import js.html.DivElement;

typedef ScoredGoal = {
	tick:Int,
	team:Int,
	points:Int
};

// Server message announcing sudden death, which ends the timed part of a game.
final SUDDEN_DEATH = "Sudden Death";

/**
	The score and game clock shown at the top of the viewer, like the
	game's HUD.

	Goal events don't say how many points a goal was worth. Like
	altistats.com, a goal is worth 2 if the replay has a score update on the
	same tick and 1 otherwise.
**/
class Scoreboard {
	final replay:Replay;
	final element:DivElement;
	final goals:Array<ScoredGoal> = [];
	final teams:Array<Int>;

	/** Tick sudden death starts, if the server announced it. **/
	final suddenDeath:Null<Int>;

	var shown = "";

	public function new(replay:Replay, element:DivElement) {
		this.replay = replay;
		this.element = element;

		var suddenDeath:Null<Int> = null;
		for (i in 0...replay.updates.length) {
			final tick = replay.ticks[i];
			final events = replay.updates[i].events;
			var twoPoints = false;
			for (e in events)
				if (e.hasScoreUpdate())
					twoPoints = true;
			for (e in events) {
				if (e.hasGoal() && e.goal.whoScored.length > 0) {
					final team = replay.gameStates[i + 1].getTeam(e.goal.whoScored[0]);
					goals.push({tick: tick, team: team, points: twoPoints ? 2 : 1});
				}
				if (e.hasChat() && suddenDeath == null && e.chat.message.indexOf(SUDDEN_DEATH) >= 0)
					suddenDeath = tick;
			}
		}
		this.suddenDeath = suddenDeath;

		teams = replay.teams.copy();
		teams.sort((a, b) -> a - b);
	}

	public function update(tick:Int) {
		final scores = [for (_ in teams) 0];
		for (g in goals)
			if (g.tick <= tick) {
				final i = teams.indexOf(g.team);
				if (i >= 0)
					scores[i] += g.points;
			}

		final clock = if (suddenDeath == null) clockText(tick) else if (tick < suddenDeath) clockText(suddenDeath - tick) else
			'<span class="sudden-death">Sudden death</span>';

		final parts = [];
		for (i in 0...teams.length) {
			if (i == 1)
				parts.push('<span class="clock">$clock</span>');
			parts.push('<span class="score" style="color:${replay.teamColorText(teams[i])}">${scores[i]}</span>');
		}
		if (teams.length < 2)
			parts.push('<span class="clock">$clock</span>');

		final html = parts.join("");
		if (html != shown) {
			element.innerHTML = html;
			shown = html;
		}
	}

	static function clockText(ticks:Int):String {
		final seconds = Std.int(ticks / 30);
		final m = Std.int(seconds / 60), s = seconds % 60;
		return '$m:${s < 10 ? "0" : ""}$s';
	}
}
