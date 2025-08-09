#!/usr/bin/env python3
import argparse
import os
import sqlite3
import sys
from pathlib import Path

class StatMaterializer:
    def __init__(self, db_path):
        self.conn = sqlite3.connect(db_path)
        self.cursor = self.conn.cursor()
        self.cursor.execute("CREATE TABLE IF NOT EXISTS stats (type, table_name, display_name)")

    def materialize(self, sql_file, table_name):
        try:
            with open(sql_file, 'r') as f:
                content = f.read().strip()

            display_name = ""
            lines = content.split('\n')
            if lines and lines[0].startswith('--'):
                display_name = lines[0][2:].strip()

            query = content
            self.cursor.execute(f"DROP TABLE IF EXISTS {table_name}")
            self.cursor.execute(f"CREATE TABLE {table_name} AS {query}")
            self.cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
            row_count = self.cursor.fetchone()[0]

            self.cursor.execute("DELETE FROM stats WHERE table_name = ?", (table_name,))
            self.cursor.execute("INSERT INTO stats (type, table_name, display_name) VALUES (?, ?, ?)",
                              ("stat", table_name, display_name))

            print(f"✓ {sql_file} ({row_count} rows)")
            return True
        except Exception as e:
            print(f"✗ {sql_file}: {e}")
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
