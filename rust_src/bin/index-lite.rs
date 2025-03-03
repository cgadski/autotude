use alti_reader::{
    collect_replay_paths, get_stem, make_pb,
    proto::{game_event::Event, GameEvent, Update},
    replay::{read_replay_file, ReplayListener},
    IndexingListener,
};
use anyhow::Result;
use clap::Parser;
use sqlite::State;
use std::path::PathBuf;

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Args {
    #[arg(long)]
    path: PathBuf,
    #[arg(long)]
    db: String,
}

struct LiteListener {
    indexer: IndexingListener,
    n_kills: usize,
}

impl ReplayListener for LiteListener {
    fn on_update(&mut self, update: &Update) -> Result<()> {
        self.indexer.on_update(update)?;
        Ok(())
    }
    fn on_event(&mut self, event: &GameEvent) -> Result<()> {
        self.indexer.on_event(event)?;
        if let Some(Event::Kill(_)) = event.event {
            self.n_kills += 1;
        }
        Ok(())
    }
}

fn main() -> Result<()> {
    let args = Args::parse();
    let paths = collect_replay_paths(&args.path);

    let conn = sqlite::open(args.db).unwrap();
    conn.execute("
        CREATE TABLE IF NOT EXISTS replays (stem STRING, started_at STRING, kills INTEGER, duration INTEGER, players INTEGER, map STRING)")?;
    let mut add_replay = conn.prepare(
        "INSERT INTO replays (stem, started_at, kills, duration, players, map) VALUES (?, ?, ?, ?, ?, ?)",
    )?;
    let mut check_replay = conn.prepare("SELECT 1 FROM replays WHERE stem = ?")?;

    let pb = make_pb(paths.len());

    for path in paths {
        let stem = get_stem(&path)?;

        // Skip if replay already exists
        check_replay.bind((1, stem.as_str()))?;
        let exists = check_replay.next()? == State::Row;
        check_replay.reset()?;

        if exists {
            pb.inc(1);
            continue;
        }

        let mut listener = LiteListener {
            indexer: IndexingListener::new(),
            n_kills: 0,
        };
        if let Ok(()) = read_replay_file(&path, &mut listener) {
            add_replay.bind((1, stem.as_str()))?;
            add_replay.bind((
                2,
                listener
                    .indexer
                    .state
                    .datetime
                    .unwrap()
                    .to_rfc3339()
                    .as_str(),
            ))?;
            add_replay.bind((3, listener.n_kills as i64))?;
            add_replay.bind((4, listener.indexer.state.current_tick as i64))?;
            add_replay.bind((5, listener.indexer.state.player_states.len() as i64))?;
            add_replay.bind((6, listener.indexer.state.map_name.unwrap().as_str()))?;
            while State::Done != add_replay.next()? {}
            add_replay.reset()?;
        }

        pb.inc(1);
    }

    pb.finish_and_clear();

    Ok(())
}
