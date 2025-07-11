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
    #[arg(long, default_value = "chat_messages.db")]
    db: String,

    #[arg(long)]
    limit: Option<usize>,
}

fn main() -> Result<()> {
    let args = Args::parse();

    let replay_dir =
        env::var("REPLAY_DIR").map_err(|_| anyhow!("REPLAY_DIR environment variable not set"))?;
    let base_path = PathBuf::from(&replay_dir);
    eprintln!("Using replay directory: {}", replay_dir);

    let mut paths = collect_replay_paths(&base_path);

    if let Some(limit) = args.limit {
        paths.truncate(limit);
        eprintln!(
            "Found {} replay files, processing {} (limited)",
            collect_replay_paths(&base_path).len(),
            paths.len()
        );
    } else {
        eprintln!("Found {} replay files", paths.len());
    }

    let conn = sqlite::open(&args.db)?;

    conn.execute(
        "
        CREATE TABLE IF NOT EXISTS chat_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            replay_stem TEXT NOT NULL,
            game_start_time TEXT,
            in_game_tick INTEGER NOT NULL,
            vapor TEXT NOT NULL,
            current_nick TEXT NOT NULL,
            team INTEGER NOT NULL,
            message TEXT NOT NULL
        )",
    )?;

    conn.execute("CREATE INDEX IF NOT EXISTS idx_replay_stem ON chat_messages(replay_stem)")?;
    conn.execute(
        "CREATE INDEX IF NOT EXISTS idx_game_start_time ON chat_messages(game_start_time)",
    )?;
    conn.execute("CREATE INDEX IF NOT EXISTS idx_vapor ON chat_messages(vapor)")?;

    eprintln!("Database created/opened: {}", args.db);

    // Create temporary table with all replay stems
    conn.execute("CREATE TEMP TABLE all_replays (replay_stem TEXT PRIMARY KEY)")?;

    let mut insert_stmt =
        conn.prepare("INSERT OR IGNORE INTO all_replays (replay_stem) VALUES (?)")?;
    for path in &paths {
        let replay_stem = get_stem(path)?;
        insert_stmt.bind((1, replay_stem.as_str()))?;
        while State::Done != insert_stmt.next()? {}
        insert_stmt.reset()?;
    }

    // Query to find replays that don't have chat messages yet
    let mut query = conn.prepare(
        "SELECT ar.replay_stem
         FROM all_replays ar
         LEFT JOIN (SELECT DISTINCT replay_stem FROM chat_messages) cm
         ON ar.replay_stem = cm.replay_stem
         WHERE cm.replay_stem IS NULL",
    )?;

    let mut paths_to_process = Vec::new();
    while let State::Row = query.next()? {
        let stem: String = query.read(0)?;
        // Find the path that corresponds to this stem
        for path in &paths {
            if get_stem(path)? == stem {
                paths_to_process.push(path.clone());
                break;
            }
        }
    }

    let already_processed = paths.len() - paths_to_process.len();
    eprintln!(
        "Found {} replays to process ({} already have chat messages)",
        paths_to_process.len(),
        already_processed
    );

    paths = paths_to_process;

    let pb = make_pb(paths.len());
    let mut processed_count = 0;
    let mut total_chat_messages = 0;

    for path in paths {
        let replay_stem = get_stem(&path)?;

        let listener = IndexingListener::new();
        let mut chat_count = 0;

        match read_replay_file(
            &path,
            &mut ChatHandler {
                indexer: listener,
                replay_stem: replay_stem.clone(),
                conn: &conn,
                chat_count: &mut chat_count,
            },
        ) {
            Ok(()) => {
                total_chat_messages += chat_count;
                processed_count += 1;
                pb.inc(1);
                pb.set_message(format!(
                    "Processed {} replays, {} chat messages",
                    processed_count, total_chat_messages
                ));
            }
            Err(e) => {
                pb.set_message(format!("Error: {}", e));
                pb.inc(1);
            }
        }
    }

    pb.finish_with_message(format!(
        "Complete. Processed {} replays, found {} chat messages",
        processed_count, total_chat_messages
    ));

    println!("Chat messages saved to {}", args.db);

    Ok(())
}

struct ChatHandler<'a> {
    indexer: IndexingListener,
    replay_stem: String,
    conn: &'a sqlite::Connection,
    chat_count: &'a mut usize,
}

impl<'a> ReplayListener for ChatHandler<'a> {
    fn on_update(&mut self, update: &Update) -> Result<()> {
        self.indexer.on_update(update)?;
        Ok(())
    }

    fn on_event(&mut self, event: &GameEvent) -> Result<()> {
        self.indexer.on_event(event)?;

        match &event.event {
            Some(Event::Chat(chat)) => {
                let player_id = PlayerId(chat.sender());

                let (vapor, nick, team) = if let Ok(key) = self.indexer.get_player_key(player_id) {
                    if let Some(player_state) = self.indexer.state.player_states.get(&key) {
                        (
                            player_state.data.vapor.clone().unwrap_or_default(),
                            player_state.nick.clone(),
                            player_state.team,
                        )
                    } else {
                        (String::new(), format!("Unknown_{}", player_id.0), 0)
                    }
                } else {
                    (String::new(), format!("Unknown_{}", player_id.0), 0)
                };

                let game_start_time = self
                    .indexer
                    .state
                    .datetime
                    .map(|dt| dt.to_rfc3339())
                    .unwrap_or_else(|| String::new());

                let mut stmt = self.conn.prepare(
                    "INSERT INTO chat_messages (replay_stem, game_start_time, in_game_tick, vapor, current_nick, team, message) VALUES (?, ?, ?, ?, ?, ?, ?)"
                )?;

                stmt.bind((1, self.replay_stem.as_str()))?;
                stmt.bind((2, game_start_time.as_str()))?;
                stmt.bind((3, self.indexer.state.current_tick as i64))?;
                stmt.bind((4, vapor.as_str()))?;
                stmt.bind((5, nick.as_str()))?;
                stmt.bind((6, team as i64))?;
                stmt.bind((7, chat.message()))?;

                while State::Done != stmt.next()? {}
                *self.chat_count += 1;
            }
            _ => {}
        }
        Ok(())
    }
}
