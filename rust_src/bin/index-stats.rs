use alti_reader::listener::{PlayerKey, PlayerState};
use alti_reader::proto::{GameEvent, Update};
use alti_reader::replay::ReplayListener;
use alti_reader::{collect_replay_paths, get_stem, make_pb, IndexingListener, ReplayState};
use anyhow::{anyhow, Result};
use chrono::DateTime;
use clap::Parser;
use csv;
use indicatif::{ProgressBar, ProgressStyle};
use postgres::{Client, NoTls, Statement, Transaction};
use std::collections::HashMap;
use std::io::{self, BufRead};
use std::path::PathBuf;

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Args {
    #[arg(long)]
    path: PathBuf,
    #[arg(long)]
    db: String,
}

struct StatsListener {}

impl ReplayListener for StatsListener {
    fn on_update(&mut self, update: &Update) -> Result<()> {
        Ok(())
    }
    fn on_event(&mut self, event: &GameEvent) -> Result<()> {
        Ok(())
    }
}

struct Indexer {}

impl Indexer {
    fn new(conn: &mut Client) -> Result<Self> {
        Ok(Self {})
    }

    fn run<'a>(&self, conn: &'a mut Transaction, path: &PathBuf) -> Result<()> {
        let path_stem: String = get_stem(path)?;

        let state: ReplayState = {
            let mut listener = IndexingListener::new();
            alti_reader::replay::read_replay_file(path, &mut listener)?;
            listener.state
        };

        Ok(())
    }
}

fn get_stems(conn: &mut Client) -> Result<Vec<String>> {
    let sql = "
        SELECT stem FROM replays NATURAL JOIN \"4ball_games\"
    ";

    let rows = conn
        .query(sql, &[])
        .map_err(|e| anyhow!("Failed to get stems: {}", e))?;
    let paths: Vec<String> = rows.iter().map(|row| row.get::<_, String>(0)).collect();
    Ok(paths)
}

fn main() -> Result<()> {
    let args: Args = Args::parse();
    let conn_str = args.out.to_string_lossy();
    let mut conn = Client::connect(&conn_str, NoTls)?;

    // Collect replay paths
    let stems = get_stems(&mut conn)?;

    println!("Total stems to index: {}", stems.len());

    // Create progress bar
    let pb = if args.progress {
        Some(make_pb(stems.len()))
    } else {
        None
    };

    let indexer = Indexer::new(&mut conn)?;

    // Handle each path
    for path in paths {
        let mut transaction = conn.transaction()?;
        let status = match indexer.run(&mut transaction, &path) {
            Ok(_) => "✓",
            Err(e) => {
                if !args.progress {
                    println!("Error indexing {:?}: {}", path, e);
                }
                "✗"
            }
        };
        if let Some(pb) = &pb {
            pb.set_message(format!(
                "{} {}",
                status,
                path.file_name().unwrap().to_string_lossy()
            ));
            pb.inc(1);
        }
        transaction.commit()?;
    }

    if let Some(pb) = pb {
        pb.finish_and_clear();
    }

    Ok(())
}
