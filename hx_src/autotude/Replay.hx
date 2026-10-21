package autotude;

import haxe.io.Bytes;
import haxe.io.BytesOutput;
import autotude.proto.MapGeometry;
import protohx.ReadingBuffer;
import haxe.io.BytesInput;
import autotude.proto.Update;
import format.gz.Reader;

@:structInit class Player {
	public final name:String;
	public final team:Int;
	// public final aceRank:Int;
	// public final level:Int;
}

@:structInit class GameState {
	public final players:Map<Int, Player>;

	public function getName(id:Int):String {
		return players.get(id)?.name ?? "??";
	}

	public function getTeam(id:Int):Int {
		return players.get(id)?.team ?? 0;
	}
}

private inline function showDigits(d:Int):String {
	if (d >= 10) {
		return Std.string(d);
	} else {
		return "0" + Std.string(d);
	}
}

function showTimestamp(frames:Int):String {
	final minutes = Std.int(frames / (60 * 30));
	frames -= minutes * 60 * 30;
	final seconds = Std.int(frames / 30);
	frames -= seconds * 30;
	final d = showDigits;
	return '${d(minutes)}:${d(seconds)}:${d(frames)}';
}

function showTimestampHtml(frames:Int):String {
	final minutes = Std.int(frames / (60 * 30));
	frames -= minutes * 60 * 30;
	final seconds = Std.int(frames / 30);
	frames -= seconds * 30;
	final d = showDigits;
	return '${d(minutes)}:${d(seconds)}<i>:${d(frames)}</i>';
}

class Replay {
	public final updates:Array<Update> = [];
	public final gameStates:Array<GameState> = [];

	/**
		Tick (frame, 1/30 s) at which each update takes effect. An update lasts
		`duration` ticks (run-length encoding of unchanged frames), so
		`updates[i]` is shown from `ticks[i]` until `ticks[i + 1]`.
	**/
	public final ticks:Array<Int> = [];

	/** Length of the replay in ticks. **/
	public var totalTicks(default, null):Int = 0;

	/** Index of the update shown at `tick`. **/
	public function updateAt(tick:Int):Int {
		// last update starting at or before tick
		var lo = 0, hi = ticks.length - 1;
		while (lo < hi) {
			final mid = (lo + hi + 1) >> 1;
			if (ticks[mid] <= tick)
				lo = mid;
			else
				hi = mid - 1;
		}
		return lo;
	}

	public var mapGeometry:MapGeometry = cast null;
	public var mapName:String = cast null;

	public final teams:Array<Int>;

	public function teamColorPoly(team:Int):Null<Int> {
		if (team == teams[0]) {
			return 0xEC8686;
		} else if (team == teams[1]) {
			return 0xAEEBAE;
		}
		return null;
	}

	// Team colours (red, blue, green, yellow, orange, purple, azure, pink,
	// brown for teams 3-11), brightened to read on the viewer's dark panels.
	static final TEAM_TEXT_COLORS = [
		"#ff6b6b", "#7a9bff", "#5cd36a", "#f2c94c", "#ff9a4d", "#c08bff", "#9ccbe0", "#ffa8a8", "#d09a6a"
	];

	public function teamColorText(team:Int):String {
		return TEAM_TEXT_COLORS[team - 3] ?? "#b8bcc8";
	}

	public function new(bytes:BytesInput) {
		final reader = new Reader(bytes);
		final decompressed = new BytesOutput();
		reader.readHeader();
		reader.readData(decompressed);
		final buf = new ReadingBuffer(new BytesInput(decompressed.getBytes()));

		final teamMap:Map<Int, Bool> = new Map();
		var players:Map<Int, Player> = new Map();

		gameStates.push({
			players: []
		});

		while (buf.bytesAvailable > 0) {
			final update = new Update();
			update.mergeDelimitedFrom(buf);
			updates.push(update);
			ticks.push(totalTicks);
			totalTicks += haxe.Int64.toInt(update.duration);

			for (event in update.events) {
				if (event.hasMapLoad()) {
					mapGeometry = event.mapLoad.map;
					mapName = event.mapLoad.name;
					continue;
				}
				if (event.hasSetPlayer()) {
					players = players.copy();
					final setPlayer = event.setPlayer;
					players.set(setPlayer.id, {
						name: setPlayer.name,
						team: setPlayer.team
					});
					continue;
				}
				if (event.hasRemovePlayer()) {
					players = players.copy();
					players.remove(event.removePlayer.id);
					continue;
				}
			}

			for (ob in update.objects) {
				if (ob.hasTeam() && ob.team > 2) {
					teamMap.set(ob.team, true);
				}
			}

			gameStates.push({
				players: players
			});
		}

		teams = [for (team in teamMap.keys()) team];
		if (mapGeometry == null || mapName == null) {
			throw "No map load event found in replay";
		}
	}
}
