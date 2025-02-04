use alti_reader::proto::{MapGeometry, Update};
use alti_reader::replay::{Player, ReplayListener};
use anyhow::Result;
use chrono::DateTime;
use duckdb::Connection;
use std::collections::HashMap;
use std::path::Path;
use walkdir::WalkDir;

struct IndexingListener {
    map_name: Option<String>,
    tick_count: usize,
}

impl IndexingListener {
    fn new() -> Self {
        Self {
            map_name: None,
            tick_count: 0,
        }
    }
}

impl ReplayListener for IndexingListener {
    fn on_game_start(&mut self, map_name: String, _map_geometry: MapGeometry) {
        self.map_name = Some(map_name);
    }

    fn on_update(&mut self, _update: &Update, _players: &HashMap<i32, Player>) {
        self.tick_count += 1;
    }
}

fn index_replay(conn: &Connection, path: &Path) -> Result<()> {
    // Check if already indexed
    let path_str = path.to_string_lossy();
    let exists: bool = conn
        .prepare("SELECT 1 FROM replays WHERE path = ?")?
        .query_map([&path_str], |row| row.get::<usize, i32>(0))?
        .next()
        .transpose()?
        .is_some();

    if exists {
        println!("Skipping already indexed replay: {}", path_str);
        return Ok(());
    }

    // Parse filename for datetime
    let filename = path.file_name().unwrap().to_string_lossy();
    let stamp = &filename[..19];
    let datetime = DateTime::parse_from_str(&format!("{}+0000", stamp), "%Y_%m_%dT%H_%M_%S%z")
        .map_err(|_| anyhow::anyhow!("Invalid datetime format in filename"))?;

    // Process replay
    let mut listener = IndexingListener::new();
    alti_reader::replay::from_path(path, &mut listener)?;

    let map_name = listener
        .map_name
        .ok_or_else(|| anyhow::anyhow!("No map name found in replay"))?;

    // Insert into database
    conn.execute(
        "INSERT INTO replays (path, map, ticks, datetime) VALUES (?, ?, ?, ?)",
        [
            path_str.as_ref(),
            map_name.as_str(),
            &listener.tick_count.to_string(),
            datetime.to_rfc3339().as_str(),
        ],
    )?;

    println!("Indexed replay: {}", path_str);
    Ok(())
}

fn main() -> Result<()> {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 || args.len() > 3 {
        println!("Usage: {} <replays-dir> [limit]", args[0]);
        std::process::exit(1);
    }

    let limit = args.get(2).and_then(|s| s.parse().ok());
    let conn = Connection::open("data/replays.db")?;

    // Create table if it doesn't exist
    conn.execute(
        "
        CREATE TABLE IF NOT EXISTS replays (
            path VARCHAR,
            map VARCHAR,
            ticks INTEGER,
            datetime TIMESTAMP,
            UNIQUE(path)
        )",
        [],
    )?;

    // Walk directory and process replays
    let mut count = 0;
    for entry in WalkDir::new(&args[1])
        .follow_links(true)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| e.path().extension().and_then(|s| s.to_str()) == Some("gz"))
    {
        let path = entry.path();
        if let Some(filename) = path.file_name().and_then(|s| s.to_str()) {
            if !filename.contains("recordings/") {
                if let Err(e) = index_replay(&conn, path) {
                    eprintln!("Error processing {}: {}", path.display(), e);
                }
                count += 1;
                println!("Processed {} replays", count);
                if let Some(limit) = limit {
                    if count >= limit {
                        println!("Reached limit of {} replays", limit);
                        break;
                    }
                }
            }
        }
    }

    Ok(())
}
