package autotude.viewer;

import js.html.DivElement;

typedef ScoreFrame = {
	tick:Int,
	pointsLeft:Int,
	pointsRight:Int
};

final SUDDEN_DEATH = "Sudden Death";

class Scoreboard {
	final replay:Replay;
	final element:DivElement;
	final frames:Array<ScoreFrame> = []; // score changes
	final teams:Array<Int>;

	final suddenDeath:Null<Int>; // sudden death start

	var shown = "";

	public function new(replay:Replay, element:DivElement) {
		this.replay = replay;
		this.element = element;
		teams = replay.teams;

		var suddenDeath:Null<Int> = null;
		var pointsLeft = 0;
		var pointsRight = 0;

		for (i in 0...replay.updates.length) {
			final tick = replay.ticks[i];
			final events = replay.updates[i].events;
			var touched = false;

			for (e in events) {
				if (e.hasGoal() && e.goal.whoScored.length > 0) {
					final team = replay.gameStates[i + 1].getTeam(e.goal.whoScored[0]);
					if (team == teams[0]) {
						pointsLeft += 1;
						touched = true;
					} else if (teams.length > 1 && team == teams[1]) {
						pointsRight += 1;
						touched = true;
					}
				}
				if (e.hasScoreUpdate() && e.scoreUpdate.hasTeam() && e.scoreUpdate.hasPoints()) {
					final team = e.scoreUpdate.team;
					if (team == teams[0]) {
						pointsLeft = e.scoreUpdate.points;
						touched = true;
					} else if (teams.length > 1 && team == teams[1]) {
						pointsRight = e.scoreUpdate.points;
						touched = true;
					}
				}
				if (e.hasChat() && suddenDeath == null && e.chat.message.indexOf(SUDDEN_DEATH) >= 0)
					suddenDeath = tick;
			}

			if (touched) {
				final frame:ScoreFrame = {
					tick: tick,
					pointsLeft: pointsLeft,
					pointsRight: pointsRight
				};
				if (frames.length > 0 && frames[frames.length - 1].tick == tick)
					frames[frames.length - 1] = frame;
				else
					frames.push(frame);
			}
		}
		this.suddenDeath = suddenDeath;
	}

	public function update(tick:Int) {
		var pointsLeft = 0;
		var pointsRight = 0;

		var f = frames.length - 1;
		while (f >= 0 && frames[f].tick > tick)
			--f;
		if (f >= 0) {
			pointsLeft = frames[f].pointsLeft;
			pointsRight = frames[f].pointsRight;
		}

		final scores = [for (i in 0...teams.length) i == 0 ? pointsLeft : pointsRight];

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
