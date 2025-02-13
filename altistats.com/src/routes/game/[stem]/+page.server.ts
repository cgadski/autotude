import { error } from '@sveltejs/kit';
import { DuckDBInstance } from '@duckdb/node-api';
import * as path from 'path';
import { readFileSync } from 'fs';

export async function load({ params }) {
	const dataDir = process.env.DATA_DIR;
	try {
		if (!dataDir) {
			throw new Error('DATA_DIR environment variable is not set');
		}

		const dbPath = path.join(dataDir, 'dump.db');
		const db = await DuckDBInstance.create(dbPath);
		const conn = await db.connect();

		// Get basic game info
		const gameReader = await conn.runAndReadAll(
			`
			SELECT key, map, datetime, ticks::float / 30 / 60 as minutes
			FROM replays
			WHERE stem = ?
		`,
			[params.stem]
		);

		const game = gameReader.getRowObjects()[0];
		if (!game) {
			throw error(404, 'Game not found');
		}

		// Get kill matrix
		const killMatrixQuery = readFileSync('./src/lib/sql/game_kills.sql', 'utf-8');
		const killsReader = await conn.runAndReadAll(killMatrixQuery, [game.key]);
		const kills = killsReader.getRowObjects();

		conn.close();

		return {
			game: {
				...game,
				datetime: new Date(game.datetime).toISOString(),
				minutes: String(game.minutes)
			},
			kills
		};
	} catch (e) {
		console.error('Database error:', e);
		throw error(500, {
			message: 'Failed to query database'
		});
	}
}
