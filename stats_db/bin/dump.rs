use alti_reader::{
    collect_replay_paths, get_stem,
    listener::{Ball, PlayerId, PlayerServerPresence},
    make_pb,
    proto::{game_event::Event, GameEvent, Update},
    replay::{read_replay_file, ReplayListener},
    IndexingListener,
};
use anyhow::{anyhow, bail, Context, Result};
use clap::Parser;
use sqlite::State;
use std::{
    collections::HashSet,
    env,
    sync::{atomic::AtomicI64, Arc},
};
use std::{path::PathBuf, sync::Mutex};
use threadpool::ThreadPool;

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Args {
    #[arg(long)]
    db: String,

    #[arg(long)]
    limit: Option<usize>,

    #[arg(long, default_value = "5")]
    workers: usize,

    #[arg(long)]
    stem: Option<String>,
}

fn mark_errored_stem(conn: &sqlite::Connection, stem: &str) -> Result<()> {
    let mut stmt = conn.prepare("INSERT OR IGNORE INTO errored (stem) VALUES (?)")?;
    stmt.bind((1, stem))?;
    stmt.next()?;
    Ok(())
}

fn init_replay_key(conn: &sqlite::Connection) -> Result<i64> {
    let mut stmt = conn.prepare("SELECT coalesce(max(replay_key) + 1, 1) FROM replays")?;
    stmt.next()?;
    Ok(stmt.read::<i64, _>(0)?)
}

fn get_stems(query: &str, args: &Args) -> Result<HashSet<String>> {
    let conn = sqlite::Connection::open(&args.db)?;
    let mut existing_stems = HashSet::new();
    let mut stmt = conn.prepare(query)?;
    while let State::Row = stmt.next()? {
        if let Ok(stem) = stmt.read::<String, _>(0) {
            existing_stems.insert(stem);
        }
    }
    Ok(existing_stems)
}

fn get_paths(args: &Args) -> Result<Vec<PathBuf>> {
    let replay_dir =
        env::var("REPLAY_DIR").map_err(|_| anyhow!("REPLAY_DIR environment variable not set"))?;
    let base_path = PathBuf::from(&replay_dir);

    eprintln!("Using replay directory: {}", replay_dir);
    let mut paths = collect_replay_paths(&base_path);

    let existing_stems = get_stems("SELECT stem FROM replays", args)?;
    let broken_stems = get_stems("SELECT stem FROM broken_replays", args)?;
    let original_count = paths.len();
    paths.retain(|p| {
        if let Ok(path_stem) = get_stem(p) {
            !existing_stems.contains(&path_stem) && !broken_stems.contains(&path_stem)
        } else {
            true
        }
    });
    eprintln!(
        "Found {} paths, {} in database, {} broken, {} to process",
        original_count,
        existing_stems.len(),
        broken_stems.len(),
        paths.len()
    );

    if let Some(stem) = &args.stem {
        paths.retain(|p| {
            if let Ok(path_stem) = get_stem(p) {
                path_stem == *stem
            } else {
                true
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
    }

    Ok(paths)
}

#[derive(Default, Debug, Clone, Copy)]
struct Progress {
    pub processed_count: i32,
    pub total_chat_messages: usize,
    pub total_goals: usize,
    pub total_kills: usize,
}

fn main() -> Result<()> {
    let args = Args::parse();

    let conn = Arc::new(sqlite::Connection::open_thread_safe(&args.db)?);
    conn.execute("begin;")?;
    let paths = get_paths(&args)?;

    let pb = make_pb(paths.len());
    let progress = Arc::new(Mutex::new(Progress::default()));
    let replay_key = Arc::new(AtomicI64::new(init_replay_key(&conn)?));

    let pool = ThreadPool::new(args.workers);
    for path in paths {
        let (conn, pb, progress, replay_key) = (
            conn.clone(),
            pb.clone(),
            progress.clone(),
            replay_key.clone(),
        );
        pool.execute(move || {
            let replay_stem = get_stem(&path).expect("Error reading stem");

            let listener = IndexingListener::new();
            let mut dump_listener = DumpListener {
                indexer: listener,
                replay_stem: replay_stem.clone(),
                conn: &conn,
                chat_count: 0,
                goal_count: 0,
                kill_count: 0,
                replay_key: replay_key.fetch_add(1, std::sync::atomic::Ordering::Relaxed),
            };

            dump_listener.clear_tables().unwrap();

            match read_replay_file(&path, &mut dump_listener) {
                Ok(()) => {
                    dump_listener.write_replay().expect("Error writing replay");
                    let p: Progress = {
                        let mut p = progress.lock().unwrap();
                        p.total_chat_messages += dump_listener.chat_count;
                        p.total_goals += dump_listener.goal_count;
                        p.total_kills += dump_listener.kill_count;
                        p.processed_count += 1;
                        *p
                    };
                    pb.set_message(format!(
                        "Processed {} replays, {} chat messages, {} goals, {} kills",
                        p.processed_count, p.total_chat_messages, p.total_goals, p.total_kills
                    ));
                }
                Err(e) => {
                    pb.println(format!("Error processing {}: {:#}", replay_stem, e));
                    if let Err(db_err) = mark_errored_stem(&conn, &replay_stem) {
                        pb.println(format!(
                            "Failed to record error for {}: {}",
                            replay_stem, db_err
                        ));
                    }
                }
            }
            pb.inc(1);
        });
    }
    pool.join();

    let p = Arc::try_unwrap(progress)
        .map_err(|_| anyhow!("Somehow, unwrapping Arc failed after joining all threads"))?
        .into_inner()?;
    pb.finish_with_message(format!(
        "Complete. Processed {} replays, {} chat messages, {} goals, {} kills",
        p.processed_count, p.total_chat_messages, p.total_goals, p.total_kills
    ));

    Arc::try_unwrap(conn)
        .map_err(|_| anyhow!("Somehow, unwrapping Arc failed after joining all threads"))?
        .execute("commit;")?;
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
            "INSERT INTO replays (replay_key, stem, map, server, duration, started_at, version) VALUES (?, ?, ?, ?, ?, ?, ?)",
        )?;

        insert_replay_stmt.bind((1, self.replay_key))?;
        insert_replay_stmt.bind((2, self.replay_stem.as_str()))?;
        insert_replay_stmt.bind((3, state.map_name.as_deref().unwrap_or("")))?;
        insert_replay_stmt.bind((4, state.server_name.as_deref().unwrap_or("")))?;
        insert_replay_stmt.bind((5, state.current_tick as i64))?;
        insert_replay_stmt.bind((6, state.datetime.map(|dt| dt.timestamp()).unwrap_or(0)))?;
        insert_replay_stmt.bind((7, state.version.as_deref().unwrap_or("")))?;

        while State::Done != insert_replay_stmt.next()? {}
        insert_replay_stmt.reset()?;

        let mut insert_player_stmt = self.conn.prepare(
            "INSERT INTO players (replay_key, player_key, nick, vapor, level, ticks_alive, team) VALUES (?, ?, ?, ?, ?, ?, ?)"
        )?;
        let mut insert_spawn_stmt = self.conn.prepare(
            "INSERT INTO spawns (replay_key, player_key, plane, red_perk, green_perk, blue_perk, start_tick, end_tick) VALUES (?, ?, ?, ?, ?, ?, ?, ?)"
        )?;

        for (_, player_state) in &state.player_states {
            let player_key = player_state.key.0 as i64;
            insert_player_stmt.bind((1, self.replay_key))?;
            insert_player_stmt.bind((2, player_key))?;
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

            for spawn in player_state.spawns.iter() {
                if let Some(loadout) = spawn.data {
                    insert_spawn_stmt.bind((1, self.replay_key))?;
                    insert_spawn_stmt.bind((2, player_key))?;
                    insert_spawn_stmt.bind((3, loadout.plane as i64))?;
                    insert_spawn_stmt.bind((4, loadout.red_perk as i64))?;
                    insert_spawn_stmt.bind((5, loadout.green_perk.map(i64::from)))?;
                    insert_spawn_stmt.bind((6, loadout.blue_perk.map(i64::from)))?;
                    insert_spawn_stmt.bind((7, spawn.start_tick as i64))?;
                    insert_spawn_stmt.bind((8, spawn.end_tick as i64))?;

                    while State::Done != insert_spawn_stmt.next()? {}
                    insert_spawn_stmt.reset()?;
                }
            }
        }

        let mut insert_possession_stmt = self.conn.prepare(
            "INSERT INTO possession (replay_key, player_key, start_tick, end_tick) VALUES (?, ?, ?, ?)"
        )?;

        for ball in state.ball.iter() {
            if let Some(Ball::Possessed { player }) = ball.data {
                insert_possession_stmt.bind((1, self.replay_key))?;
                insert_possession_stmt.bind((2, player.0 as i64))?;
                insert_possession_stmt.bind((3, ball.start_tick as i64))?;
                insert_possession_stmt.bind((4, ball.end_tick as i64))?;

                while State::Done != insert_possession_stmt.next()? {}
                insert_possession_stmt.reset()?;
            }
        }

        Ok(())
    }

    fn clear_tables(&self) -> Result<()> {
        for table in ["messages", "goals", "kills", "damage"] {
            let mut stmt = self
                .conn
                .prepare(&format!("DELETE FROM {} WHERE replay_key = ?", table))?;
            stmt.bind((1, self.replay_key))?;
            stmt.next()?;
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
                "INSERT INTO messages (replay_key, player_key, tick, chat_message) VALUES (?, ?, ?, ?)"
            )?;

            let sender = self.indexer.get_present_player_key(PlayerId(chat.sender()));

            stmt.bind((1, self.replay_key))?;
            if let Ok(sender_key) = sender {
                stmt.bind((2, sender_key.0 as i64))?;
            } else {
                stmt.bind((2, sqlite::Value::Null))?;
            }
            stmt.bind((3, self.indexer.state.current_tick as i64))?;
            stmt.bind((4, chat.message()))?;

            while State::Done != stmt.next()? {}
            self.chat_count += 1;
        }

        if let Some(Event::Goal(goal)) = &event.event {
            if let Some(&scorer) = goal.who_scored.first() {
                let mut stmt = self.conn.prepare(
                    "INSERT INTO goals (replay_key, player_key, tick, team) VALUES (?, ?, ?, ?)",
                )?;

                let scorer_key = match self.indexer.get_player_key(PlayerId(scorer))? {
                    PlayerServerPresence::Present(k) => Some(k),
                    // players can still score shortly after leaving (in practice, absent goals seem
                    // always attributed to the null player, though)
                    PlayerServerPresence::Absent(k) => Some(k),
                    PlayerServerPresence::NullPlayer => None,
                };
                let scorer = scorer_key
                    .map(|k| self.indexer.get_player(k))
                    .transpose()
                    .with_context(|| format!("No player state with id {:?} for goal", scorer))?;

                stmt.bind((1, self.replay_key))?;
                stmt.bind((2, scorer_key.map(|k| k.0 as i64)))?;
                stmt.bind((3, self.indexer.state.current_tick as i64))?;
                stmt.bind((4, scorer.map(|p| p.team as i64)))?;

                while State::Done != stmt.next()? {}
                self.goal_count += 1;
            }
        }

        if let Some(Event::Kill(kill)) = &event.event {
            let mut stmt = self.conn.prepare(
                "INSERT INTO kills (replay_key, who_killed, who_died, tick) VALUES (?, ?, ?, ?)",
            )?;

            let died_key = match self.indexer.get_player_key(PlayerId(kill.who_died()))? {
                PlayerServerPresence::Present(k) => Some(k),
                // absent players should not have planes, but altitude sometimes bugs and retains
                // owner-less planes: ignore them
                PlayerServerPresence::Absent(_) => None,
                PlayerServerPresence::NullPlayer => None,
            };
            if let Some(died_key) = died_key {
                stmt.bind((1, self.replay_key))?;

                if kill.who_killed.is_none() {
                    stmt.bind((2, sqlite::Value::Null))?;
                } else {
                    let killer_id = PlayerId(kill.who_killed());
                    let killer_key = match self.indexer.get_player_key(killer_id)? {
                        PlayerServerPresence::Present(k) => k,
                        // players can still get kills shortly after leaving
                        PlayerServerPresence::Absent(k) => k,
                        // kills by null player not yet observed, even when killer leaves before
                        // kill. to represent kills by null we would need to differentiate them
                        // from crashes, probably by introducing a dedicated crash table
                        PlayerServerPresence::NullPlayer => bail!(
                            "Unexpected kill by null player at tick {}",
                            self.indexer.state.current_tick
                        ),
                    };
                    stmt.bind((2, killer_key.0 as i64))?;
                }
                stmt.bind((3, died_key.0 as i64))?;
                stmt.bind((4, self.indexer.state.current_tick as i64))?;

                while State::Done != stmt.next()? {}
                self.kill_count += 1;
            }
        }

        if let Some(Event::Damage(damage)) = &event.event {
            if damage.source() == damage.target() {
                return Ok(());
            }

            if damage.source() == 4294967295 {
                return Ok(()); // sinister damage dealt by server
            }

            let mut stmt = self.conn.prepare(
                "INSERT INTO damage (replay_key, source_key, target_key, tick, amount) VALUES (?, ?, ?, ?, ?)",
            )?;

            stmt.bind((1, self.replay_key))?;

            let target_key = match self.indexer.get_player_key(PlayerId(damage.target()))? {
                PlayerServerPresence::Present(k) => k,
                PlayerServerPresence::Absent(k) => k,
                PlayerServerPresence::NullPlayer => bail!(
                    "Unexpected damage to non-existent player at tick {}",
                    self.indexer.state.current_tick
                ),
            };

            let source_key = match self.indexer.get_player_key(PlayerId(damage.source()))? {
                PlayerServerPresence::Present(k) => k,
                PlayerServerPresence::Absent(k) => k,
                PlayerServerPresence::NullPlayer => bail!(
                    "Unexpected damage from non-existent player at tick {}",
                    self.indexer.state.current_tick
                ),
            };

            stmt.bind((2, source_key.0 as i64))?;
            stmt.bind((3, target_key.0 as i64))?;
            stmt.bind((4, self.indexer.state.current_tick as i64))?;
            stmt.bind((5, damage.amount() as i64))?;

            while State::Done != stmt.next()? {}
        }

        Ok(())
    }
}
