package autotude;

import autotude.Replay.GameState;
import sys.FileStat;
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
	final replay:Replay;
	final conn:Connection;
	final file:String;
	final stats:FileStat;
	final replayId:Int;

	public function new(replay:Replay, conn:Connection, file:String, stats:FileStat) {
		this.replay = replay;
		this.conn = conn;
		this.file = file;
		this.stats = stats;

		conn.request('INSERT OR IGNORE INTO replays (file, map, ticks) VALUES (
			${conn.quote(file)}, 
			${conn.quote(replay.mapName)}, 
			${replay.updates.length}
		)');
		this.replayId = conn.request('SELECT replay_id FROM replays WHERE file = ${conn.quote(file)}').getIntResult(0);
	}

	public function index() {
		var idx = 0;
		for (update in replay.updates) {
			for (event in update.events) {
				onEvent(idx, replay.gameStates[idx], event);
			}
		}
	}

	public var numMapLoads:Int = 0;

	public function onEvent(tick:Int, state:GameState, event:GameEvent) {
		if (event.chat != null) {
			final name = state.getName(event.chat.sender);
			final chat = event.chat.message;
			conn.request('INSERT INTO chat (replay_id, tick, name, chat) VALUES (
				${replayId},
				${tick},
				${conn.quote(name)},
				${conn.quote(chat)}
			)');
		}
	}
}

class Indexer {
	public static function main() {
		final dir = Sys.args()[0];
		Sys.println(dir);

		final files = FileSystem.readDirectory(Sys.args()[0]);
		Sys.println(files.length);
		var totalUpdates = 0;

		final conn = Sqlite.open('replay_index.db');

		conn.request('CREATE TABLE IF NOT EXISTS replays (replay_id INTEGER PRIMARY KEY, file TEXT, map TEXT, ticks INTEGER)');
		conn.request('CREATE UNIQUE INDEX IF NOT EXISTS replays_idx ON replays (file)');
		conn.request('CREATE TABLE IF NOT EXISTS players (replay_id INTEGER, name TEXT, team INTEGER, PRIMARY KEY (replay_id, name))');
		conn.request('CREATE TABLE IF NOT EXISTS chat (replay_id INTEGER, tick INTEGER, name TEXT, chat TEXT)');

		for (file in files) {
			final path = Sys.args()[0] + file;
			final stats = FileSystem.stat(path);
			final bytes = File.getBytes(path);
			final replay = new Replay(new BytesInput(bytes));

			final summary = new ReplayIndexer(replay, conn, file, stats);
			conn.startTransaction();
			summary.index();
			conn.commit();
		}

		// final minutes = Std.int(totalUpdates / (30 * 60));
		// Sys.println('Total time recorded: $minutes minutes');

		conn.close();
	}
}
