#!/usr/bin/env python3
import argparse
import os
import sqlite3
import sys
from pathlib import Path
from dataclasses import dataclass
from typing import List
import json

@dataclass
class StatQuery:
    key: str
    stat_table: str
    query_name: str
    description: str
    attributes: List[str]
    sql: str

table_prefixes = [
    ('_', 'global_stats'),
    ('p_', 'player_stats'),
    ('g_', 'game_stats'),
]

def read_query(sql_file: Path) -> StatQuery:
    with open(sql_file, 'r') as f:
        content = f.read().strip()

    lines = content.split('\n')
    description = ""
    attributes = []

    if lines and lines[0].startswith('--'):
        description = lines[0][2:].strip()

    if len(lines) > 1 and lines[1].startswith('--'):
        attributes = lines[1][2:].strip().split()

    stem = sql_file.stem
    for prefix, table in table_prefixes:
        if stem.startswith(prefix):
            return StatQuery(
                key=stem[len(prefix):],
                stat_table=table,
                query_name = stem,
                description=description,
                attributes=attributes,
                sql=content
            )

    raise ValueError(f"No matching prefix for {stem}")


class StatMaterializer:
    def __init__(self, db_path):
        self.conn = sqlite3.connect(db_path)
        self.cursor = self.conn.cursor()
        self.cursor.executescript("""
            DROP TABLE IF EXISTS stats;
            CREATE TABLE stats (
                stat_key INTEGER PRIMARY KEY,
                query_name TEXT,
                description TEXT,
                attributes JSON
            );

            DROP TABLE IF EXISTS global_stats;
            CREATE TABLE global_stats (
                stat_key INTEGER REFERENCES stats (stat_key),
                time_bin DEFAULT null,
                stat
            );

            DROP TABLE IF EXISTS player_stats;
            CREATE TABLE player_stats (
                stat_key INTEGER REFERENCES stats (stat_key),
                handle,
                time_bin,
                plane,
                stat
            );

            DROP TABLE IF EXISTS game_stats;
            CREATE TABLE game_stats (
                stat_key INTEGER REFERENCES stats (stat_key),
                replay_key,
                stat
            );
        """)
        self.next_stat_key = 1

    def materialize(self, query_file, table_name):
        try:
            stat = read_query(query_file)
            stat_key = self.next_stat_key
            self.next_stat_key += 1

            self.cursor.execute(
                "INSERT INTO stats VALUES (?, ?, ?, ?)",
                (stat_key, stat.query_name, stat.description, json.dumps(stat.attributes))
            )

            self.cursor.execute(f"""
                INSERT INTO {stat.stat_table}
                SELECT {stat_key} AS stat_key, *
                FROM ({stat.sql})
            """)

            print(f"✓ {query_file}")
            return True
        except Exception as e:
            print(f"✗ {query_file}: {e}")
            return False

    def close(self):
        self.conn.commit()
        self.conn.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", required=True)
    parser.add_argument("--stats-dir", required=True)
    args = parser.parse_args()

    db_path, stats_dir = args.db, Path(args.stats_dir)

    if not os.path.exists(db_path) or not stats_dir.exists():
        print("Database or stats directory not found")
        sys.exit(1)

    sql_files = list(stats_dir.glob("*.sql"))

    materializer = StatMaterializer(db_path)
    n_success = 0
    for f in sorted(sql_files):
        n_success += materializer.materialize(f, f.stem)
    materializer.close()

    print(f"Materialized {n_success}/{len(sql_files)} stat tables")
    if n_success != len(sql_files):
        sys.exit(1)
