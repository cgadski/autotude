import { error } from '@sveltejs/kit';
import { DuckDBInstance } from '@duckdb/node-api';
import * as path from 'path';
import { readFileSync } from 'fs';

export async function load() {
	const dataDir = process.env.DATA_DIR;
	try {
		if (!dataDir) {
			throw new Error('DATA_DIR environment variable is not set');
		}

		const dbPath = path.join(dataDir, 'dump.db');
		const db = await DuckDBInstance.create(dbPath);
		const conn = await db.connect();

		const statsReader = await conn.runAndReadAll(`
			SELECT
				COUNT(*) as replay_count,
				SUM(ticks)::float / 30 / 3600 as total_hours
			FROM replays
		`);
		const stats = statsReader.getRowObjects()[0];

		const recentGamesQuery = readFileSync('./src/lib/sql/games.sql', 'utf-8');
		const gamesReader = await conn.runAndReadAll(recentGamesQuery);
		const recentGames = gamesReader.getRowObjects().map((game) => ({
			...game,
			datetime: new Date(game.datetime).toISOString(),
			minutes: String(game.minutes),
			players: game.players || '[]' // ensure we always have a valid JSON string
		}));

		conn.close();

		return {
			replayCount: stats.replay_count,
			totalHours: stats.total_hours,
			recentGames: recentGames
		};
	} catch (e) {
		console.error('Database error:', e);
		throw error(500, {
			message: 'Failed to query database'
		});
	}
}
