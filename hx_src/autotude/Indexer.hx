package autotude;

import haxe.io.Eof;
import autotude.Replay.Player;
import cpp.ObjectType;
import haxe.io.Path;

using StringTools;

import autotude.Replay.GameState;
import sys.db.Connection;
import sys.db.Sqlite;
import sys.FileSystem;
import haxe.io.Bytes;
import autotude.proto.GameObject;
import autotude.proto.GameEvent;
import haxe.io.BytesInput;
import sys.io.File;
import haxe.Json;

private class ReplayIndexer {
	public static function index(path:String, conn:Connection) {
		final req = conn.request('SELECT replay_id FROM replays WHERE path = ${conn.quote(path)}');
		if (req.length > 0) {
			return;
		}

		Sys.println('Indexing ${path}...');

		try {
			final bytes = File.getBytes(path);
			final replay = new Replay(new BytesInput(bytes));
			final timestamp = Math.round(FileSystem.stat(path).ctime.getTime() / 1000);

			final map = replay.mapName;

			conn.request('INSERT INTO replays (path, map, ticks, time) VALUES (
				${conn.quote(path)}, 
				${conn.quote(replay.mapName)}, 
				${replay.updates.length},
				${timestamp}
			)');

			final id = conn.lastInsertId();
			Sys.println(' indexed with id ${id}');
			final indexer = new ReplayIndexer(id, replay, conn);
			indexer.process();
		} catch (e:Eof) {
			Sys.println(' ${path} not finished');
		}
	}

	final id:Int;
	final replay:Replay;
	final conn:Connection;

	final playerTimes:Map<String, Int> = new Map();
	final playerTeams:Map<String, Int> = new Map();

	public function new(id:Int, replay:Replay, conn:Connection) {
		this.id = id;
		this.replay = replay;
		this.conn = conn;
	}

	public function process() {
		var idx = 0;
		for (update in replay.updates) {
			final state = replay.gameStates[idx];
			for (event in update.events) {
				onEvent(idx, state, event);
			}
			for (object in update.objects) {
				if (object.type < 5) {
					final name = state.getName(object.owner);
					playerTimes[name] = 1 + (playerTimes.get(name) ?? 0);
					playerTeams[name] = object.team;
				}
			}
			idx++;
		}

		for (player in playerTimes.keys()) {
			final team = playerTeams.get(player);
			final ticksAlive = playerTimes.get(player);
			conn.request('INSERT INTO players (replay_id, name, team, ticks_alive) VALUES (
				${id},
				${conn.quote(player)},
				${team},
				${ticksAlive}
			)');
		}
	}

	public function onEvent(tick:Int, state:GameState, event:GameEvent) {
		if (event.chat != null) {
			final name = state.getName(event.chat.sender);
			final chat = event.chat.message;
			conn.request('INSERT INTO messages (replay_id, tick, name, message) VALUES (
				${id},
				${tick},
				${conn.quote(name)},
				${conn.quote(chat)}
			)');
		}
		if (event.goal != null) {
			if (event.goal.whoScored.length == 0) {
				Sys.println("Goal with no scored player!");
				return;
			}
			final player = state.getName(event.goal.whoScored[0]);
			conn.request('INSERT INTO goals (replay_id, tick, name) VALUES (
				${id},
				${tick},
				${conn.quote(player)}
			)');
		}
	}
}

class Indexer {
	public static function main() {
		final dir = Path.addTrailingSlash(Path.normalize(Sys.args()[0]));
		Sys.println(dir);

		final files = [for (f in FileSystem.readDirectory(dir)) if (f.endsWith('.pb.gz')) f];
		Sys.println('Indexing ${files.length} replay files in $dir.');

		final conn = Sqlite.open('replay_index.db');

		conn.request('CREATE TABLE IF NOT EXISTS replays (
			replay_id INTEGER PRIMARY KEY, 
			path TEXT, 
			map TEXT, 
			ticks INTEGER,
			time INTEGER
		)');
		conn.request('CREATE UNIQUE INDEX IF NOT EXISTS replays_idx ON replays (path)');
		conn.request('CREATE TABLE IF NOT EXISTS players (
			replay_id INTEGER, 
			name TEXT, 
			team INTEGER, 
			ticks_alive INTEGER 
		)');
		conn.request('CREATE INDEX IF NOT EXISTS players_idx ON players (replay_id)');
		conn.request('CREATE INDEX IF NOT EXISTS players_idx_reverse ON players (name)');
		conn.request('CREATE TABLE IF NOT EXISTS messages (
			replay_id INTEGER, 
			tick INTEGER, 
			name TEXT, 
			message TEXT
		)');
		conn.request('CREATE TABLE IF NOT EXISTS goals (
			replay_id INTEGER, 
			tick INTEGER, 
			name TEXT
		)');

		for (file in files) {
			conn.startTransaction();
			ReplayIndexer.index(dir + file, conn);
			conn.commit();
		}

		conn.close();
	}
}
