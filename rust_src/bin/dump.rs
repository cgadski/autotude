use alti_reader::{
    collect_replay_paths, get_stem,
    listener::PlayerId,
    make_pb,
    proto::{game_event::Event, GameEvent, Update},
    replay::{read_replay_file, ReplayListener},
    IndexingListener,
};
use anyhow::{anyhow, Result};
use clap::Parser;
use sqlite::State;
use std::env;
use std::path::PathBuf;

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Args {
    #[arg(long, default_value = "data.db")]
    db: String,

    #[arg(long)]
    limit: Option<usize>,

    #[arg(long)]
    stem: Option<String>,
}

fn get_paths(args: &Args) -> Result<Vec<PathBuf>> {
    let replay_dir =
        env::var("REPLAY_DIR").map_err(|_| anyhow!("REPLAY_DIR environment variable not set"))?;
    let base_path = PathBuf::from(&replay_dir);

    eprintln!("Using replay directory: {}", replay_dir);
    let mut paths = collect_replay_paths(&base_path);

    if let Some(stem) = &args.stem {
        paths.retain(|p| {
            if let Ok(path_stem) = get_stem(p) {
                path_stem == *stem
            } else {
                false
            }
        });
        eprintln!("Filtering for stem: {}", stem);
        eprintln!("Found {} matching recordings", paths.len());
    } else if let Some(limit) = args.limit {
        let total = paths.len();
        paths.truncate(limit);
        eprintln!(
            "Found {} recordings, processing {} (limited)",
            total,
            paths.len()
        );
    } else {
        eprintln!("Found {} recordings", paths.len());
    }

    Ok(paths)
}

fn main() -> Result<()> {
    let args = Args::parse();

    let conn = sqlite::open(&args.db)?;
    let paths = get_paths(&args)?;

    let pb = make_pb(paths.len());
    let mut processed_count = 0;
    let mut total_chat_messages = 0;
    let mut total_goals = 0;
    let mut total_kills = 0;
    let mut replay_key = 1;

    for path in paths {
        let replay_stem = get_stem(&path)?;

        let listener = IndexingListener::new();
        let mut dump_listener = DumpListener {
            indexer: listener,
            replay_stem: replay_stem.clone(),
            conn: &conn,
            chat_count: 0,
            goal_count: 0,
            kill_count: 0,
            replay_key: replay_key,
        };

        match read_replay_file(&path, &mut dump_listener) {
            Ok(()) => {
                dump_listener.write_replay()?;
                total_chat_messages += dump_listener.chat_count;
                total_goals += dump_listener.goal_count;
                total_kills += dump_listener.kill_count;
                processed_count += 1;
                replay_key += 1;
                pb.inc(1);
                pb.set_message(format!(
                    "Processed {} replays, {} chat messages, {} goals, {} kills",
                    processed_count, total_chat_messages, total_goals, total_kills
                ));
            }
            Err(e) => {
                pb.set_message(format!("Error processing {}: {}", replay_stem, e));
                pb.inc(1);
            }
        }
    }

    pb.finish_with_message(format!(
        "Complete. Processed {} replays, {} chat messages, {} goals, {} kills",
        processed_count, total_chat_messages, total_goals, total_kills
    ));

    eprintln!("Database saved to: {}", args.db);

    Ok(())
}

struct DumpListener<'a> {
    indexer: IndexingListener,
    replay_stem: String,
    conn: &'a sqlite::Connection,
    chat_count: usize,
    goal_count: usize,
    kill_count: usize,
    replay_key: i64,
}

impl<'a> DumpListener<'a> {
    fn write_replay(&mut self) -> Result<()> {
        let state = &self.indexer.state;

        let mut insert_replay_stmt = self.conn.prepare(
            "INSERT INTO replays (replay_key, stem, map, server, duration, started_at) VALUES (?, ?, ?, ?, ?, ?)",
        )?;

        insert_replay_stmt.bind((1, self.replay_key))?;
        insert_replay_stmt.bind((2, self.replay_stem.as_str()))?;
        insert_replay_stmt.bind((3, state.map_name.as_deref().unwrap_or("")))?;
        insert_replay_stmt.bind((4, state.server_name.as_deref().unwrap_or("")))?;
        insert_replay_stmt.bind((5, state.current_tick as i64))?;
        insert_replay_stmt.bind((6, state.datetime.map(|dt| dt.timestamp()).unwrap_or(0)))?;

        while State::Done != insert_replay_stmt.next()? {}
        insert_replay_stmt.reset()?;

        let mut insert_player_stmt = self.conn.prepare(
            "INSERT INTO players (replay_key, player_key, nick, vapor, level, ticks_alive, team) VALUES (?, ?, ?, ?, ?, ?, ?)"
        )?;

        for (_, player_state) in &state.player_states {
            insert_player_stmt.bind((1, self.replay_key))?;
            insert_player_stmt.bind((2, player_state.key.0 as i64))?;
            insert_player_stmt.bind((3, player_state.nick.as_str()))?;
            insert_player_stmt.bind((
                4,
                player_state
                    .data
                    .vapor
                    .as_ref()
                    .map(|s| s.as_str())
                    .unwrap_or(""),
            ))?;
            insert_player_stmt.bind((5, player_state.data.level.map(|l| l as i64).unwrap_or(0)))?;
            insert_player_stmt.bind((6, player_state.ticks_alive as i64))?;
            insert_player_stmt.bind((7, player_state.team as i64))?;

            while State::Done != insert_player_stmt.next()? {}
            insert_player_stmt.reset()?;
        }

        Ok(())
    }
}

impl<'a> ReplayListener for DumpListener<'a> {
    fn on_update(&mut self, update: &Update) -> Result<()> {
        self.indexer.on_update(update)?;
        Ok(())
    }

    fn on_event(&mut self, event: &GameEvent) -> Result<()> {
        self.indexer.on_event(event)?;

        if let Some(Event::Chat(chat)) = &event.event {
            let mut stmt = self.conn.prepare(
                "INSERT INTO messages (replay_key, player_key, tick, chat_team, chat_message) VALUES (?, ?, ?, ?, ?)"
            )?;

            let player_id = PlayerId(chat.sender());

            stmt.bind((1, self.replay_key))?;
            stmt.bind((2, player_id.0 as i64))?;
            stmt.bind((3, self.indexer.state.current_tick as i64))?;
            stmt.bind((4, ""))?;
            stmt.bind((5, chat.message()))?;

            while State::Done != stmt.next()? {}
            self.chat_count += 1;
        }

        if let Some(Event::Goal(goal)) = &event.event {
            if let Some(&scorer) = goal.who_scored.first() {
                let mut stmt = self.conn.prepare(
                    "INSERT INTO goals (replay_key, player_key, tick, team) VALUES (?, ?, ?, ?)",
                )?;

                let scorer_key = self.indexer.get_player_key(PlayerId(scorer))?;
                let team = self
                    .indexer
                    .state
                    .player_states
                    .get(&scorer_key)
                    .map(|p| p.team)
                    .unwrap_or(0);

                stmt.bind((1, self.replay_key))?;
                stmt.bind((2, scorer_key.0 as i64))?;
                stmt.bind((3, self.indexer.state.current_tick as i64))?;
                stmt.bind((4, team as i64))?;

                while State::Done != stmt.next()? {}
                self.goal_count += 1;
            }
        }

        if let Some(Event::Kill(kill)) = &event.event {
            let mut stmt = self.conn.prepare(
                "INSERT INTO kills (replay_key, who_killed, who_died, tick) VALUES (?, ?, ?, ?)",
            )?;

            stmt.bind((1, self.replay_key))?;
            if kill.who_killed.is_none() {
                stmt.bind((2, sqlite::Value::Null))?;
            } else {
                stmt.bind((2, kill.who_killed() as i64))?;
            }
            stmt.bind((3, kill.who_died() as i64))?;
            stmt.bind((4, self.indexer.state.current_tick as i64))?;

            while State::Done != stmt.next()? {}
            self.kill_count += 1;
        }

        Ok(())
    }
}
