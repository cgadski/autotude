package autotude;

import autotude.Replay.showTimestamp;
import autotude.Replay.GameState;
import haxe.io.Bytes;
import autotude.proto.GameObject;
import autotude.proto.GameEvent;
import haxe.io.BytesInput;
import sys.io.File;

class ReplaySummary {
	final bytes:Bytes;
	final replay:Replay;

	public function new(bytes:Bytes, replay:Replay) {
		this.bytes = bytes;
		this.replay = replay;

		var i = 0;
		for (update in replay.updates) {
			for (event in update.events) {
				onEvent(event, replay.gameStates[i], (s) -> {
					Sys.println('${showTimestamp(i)}: $s');
				});
			}
			for (object in update.objects) {
				onObject(object);
			}
			i++;
		}
	}

	public var numMapLoads:Int = 0;
	public var numPlayerSets:Int = 0;
	public var numGoals:Int = 0;

	public function onEvent(event:GameEvent, state:GameState, p:(String) -> Void) {
		if (event.hasMapLoad()) {
			p('map load ${event.mapLoad.name}');
			numMapLoads += 1;
		}
		if (event.hasSetPlayer()) {
			p('set player ${event.setPlayer.id}: ${event.setPlayer.name}');
			numPlayerSets += 1;
		}
		if (event.hasRemovePlayer()) {
			p('remove player ${event.removePlayer.id}');
		}
		if (event.hasGoal()) {
			final team = state.players.get(event.goal.whoScored[0])?.team;
			p('${state.getName(event.goal.whoScored[0])} scored goal for team $team');
			numGoals += 1;
		}
		if (event.hasChat()) {
			p('${state.getName(event.chat.sender)}: ${event.chat.message}');
		}
		// if (event.hasDamage()) {
		// 	final damage = event.damage;
		// 	final source = state.getName(damage.source);
		// 	final target = state.getName(damage.target);
		// 	final ha = "";
		// 	// p('$source -> $target: ${damage.amount} $ha');
		// }
		if (event.hasKill()) {
			final kill = event.kill;
			final name = state.getName(kill.whoDied);
			if (state.players.get(kill.whoDied) == null) {
				p([for (k in state.players.keys()) k].toString());
			}
			if (kill.whoKilled != null) {
				p('${state.getName(kill.whoKilled)} killed ${name}');
			} else {
				p('${name} crashed');
			}
		}
	}

	public var maxUid:Int = 0;
	public var minPosX:Int = 0;
	public var minPosY:Int = 0;
	public var maxPosX:Int = 0;
	public var maxPosY:Int = 0;

	public function onObject(object:GameObject) {
		if (object.uid != null) {
			if (object.uid > maxUid)
				maxUid = object.uid;
		}
		if (object.positionX != null) {
			maxPosX = Std.int(Math.max(maxPosX, object.positionX));
			minPosX = Std.int(Math.min(minPosX, object.positionX));
		}
		if (object.positionY != null) {
			maxPosY = Std.int(Math.max(maxPosY, object.positionY));
			minPosY = Std.int(Math.min(minPosY, object.positionY));
		}
	}

	public function show() {
		final seconds = replay.updates.length / 30;
		Sys.println('----');
		Sys.println('replay statistics');
		Sys.println('----');
		Sys.println('map loads: $numMapLoads');
		Sys.println('player sets: $numPlayerSets');
		Sys.println('goals: $numGoals');
		Sys.println('teams: ${replay.teams}');
		Sys.println('duration: ${Std.int(seconds)} seconds');
		Sys.println('distinct objects: ${maxUid + 1}');
		Sys.println('x range: $minPosX to $maxPosX');
		Sys.println('y range: $minPosY to $maxPosY');
		Sys.println('kilobytes: ${bytes.length / 1000}');
		Sys.println('kb per minute: ${Std.int((60 / 1000) * (bytes.length / seconds))}');
	}
}

class ReplayTool {
	static function main() {
		final bytes = File.getBytes(Sys.args()[0]);
		final replay = new Replay(new BytesInput(bytes));
		final summary = new ReplaySummary(bytes, replay);
		summary.show();
	}
}
