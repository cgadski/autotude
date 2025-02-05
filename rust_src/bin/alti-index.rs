use alti_reader::proto::game_event::Event;
use alti_reader::proto::{
    GameEvent, GameObject, MapGeometry, RemovePlayerEvent, SetPlayerEvent, Update,
};
use alti_reader::replay::{ReplayListener, Result as ReplayResult};
use anyhow::{anyhow, Result};
use chrono::DateTime;
use clap::Parser;
use duckdb::{params, Connection};
use indicatif::{ProgressBar, ProgressStyle};
use std::collections::HashMap;
use std::io::{self, BufRead};
use std::path::PathBuf;
use walkdir::WalkDir;

#[derive(Debug, Clone, Copy, Hash, Eq, PartialEq)]
struct PlayerId(u32);

#[derive(Debug, Clone, Copy, Hash, Eq, PartialEq)]
struct PlayerKey(u32);

impl From<u32> for PlayerId {
    fn from(id: u32) -> Self {
        PlayerId(id)
    }
}

impl From<u32> for PlayerKey {
    fn from(key: u32) -> Self {
        PlayerKey(key)
    }
}

const BUFFER_LEN: usize = 1024;

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Args {
    #[arg(long, conflicts_with = "stdin")]
    replays: Option<PathBuf>,

    #[arg(long, conflicts_with = "replays")]
    stdin: bool,

    #[arg(short, long)]
    out: PathBuf,

    #[arg(long)]
    limit: Option<usize>,

    #[arg(short, long, default_value="false", action = clap::ArgAction::SetTrue)]
    progress: bool,

    #[arg(long, default_value="false", action = clap::ArgAction::SetTrue)]
    dump: bool,
}

#[derive(Debug)]
struct PlayerState {
    key: PlayerKey,
    data: SetPlayerEvent,
    team: Option<i32>,
    nick: String,
    ticks_alive: i32,
}

struct IndexingListener<'a> {
    dump: bool,

    map_name: Option<String>,
    replay_key: u32,
    conn: &'a Connection,
    current_tick: usize,
    id_to_key: HashMap<PlayerId, PlayerKey>, // maps game ID to our allocated key
    player_states: HashMap<PlayerKey, PlayerState>, // maps our key to player state

    state_buffer: Vec<[u32; 11]>,
}

impl<'a> IndexingListener<'a> {
    fn new(replay_key: u32, conn: &'a Connection, dump: bool) -> Self {
        Self {
            dump,

            map_name: None,
            replay_key,
            conn,
            current_tick: 0,

            id_to_key: HashMap::new(),
            player_states: HashMap::new(),

            state_buffer: Vec::with_capacity(if dump { BUFFER_LEN } else { 0 }),
        }
    }

    fn on_plane(&mut self, id: PlayerId, plane: &GameObject) -> Result<()> {
        let key = if let Ok(k) = self.get_player_key(id) {
            k
        } else {
            return Ok(());
        };

        if let Some(state) = self.player_states.get_mut(&key) {
            state.ticks_alive += 1;
            if let Some(team) = plane.team {
                state.team = Some(team as i32);
            }
        }

        if self.dump {
            self.state_buffer.push([
                key.0,
                self.current_tick as u32,
                plane.r#type() as u32,
                plane.team(),
                plane.position_x(),
                plane.position_y(),
                plane.angle(),
                plane.health(),
                plane.ammo(),
                plane.throttle(),
                plane.bars(),
            ]);
            self.write_buffered(false)?;
        }
        Ok(())
    }

    fn on_set_player(&mut self, data: &SetPlayerEvent) -> Result<()> {
        let id = PlayerId(data.id());

        // Start a new player record if no player was previously registered at this id
        if !self.id_to_key.contains_key(&id) {
            let key: PlayerKey = self
                .conn
                .query_row("SELECT nextval('player_keys')", [], |row| row.get(0))
                .map(|k| PlayerKey(k))?;

            let name: &String = data
                .name
                .as_ref()
                .ok_or_else(|| anyhow!("Player with no nickname."))?;

            let state = PlayerState {
                key,
                nick: name.clone(),
                data: data.clone(),
                team: None,
                ticks_alive: 0,
            };

            self.id_to_key.insert(id, key);
            self.player_states.insert(key, state);
        }
        Ok(())
    }

    fn on_remove_player(&mut self, data: &RemovePlayerEvent) -> Result<()> {
        let id: PlayerId = PlayerId(data.id());
        self.id_to_key.remove(&id);
        Ok(())
    }

    fn get_player_key(&mut self, id: PlayerId) -> Result<PlayerKey> {
        self.id_to_key
            .get(&id)
            .ok_or_else(|| anyhow!("Unregistered player id used."))
            .map(|x| x.clone())
    }

    fn write_buffered(&mut self, force: bool) -> Result<()> {
        if force || self.state_buffer.len() >= BUFFER_LEN {
            let mut app = self.conn.appender("states")?;
            for row in &self.state_buffer {
                // lol
                app.append_row([
                    &row[0], &row[1], &row[2], &row[3], &row[4], &row[5], &row[6], &row[7],
                    &row[8], &row[9], &row[10],
                ])?;
            }
            self.state_buffer.clear();
        }

        Ok(())
    }

    fn write_players(&mut self) -> Result<()> {
        let mut app = self.conn.appender("players")?;

        for state in self.player_states.values() {
            app.append_row(params![
                state.key.0,
                self.replay_key,
                state.nick,
                state.data.vapor,
                state.data.level.map(|v| v as i32),
                state.data.ace_rank.map(|v| v as i32),
                state.ticks_alive,
            ])?;
        }
        Ok(())
    }
}

impl<'a> ReplayListener for IndexingListener<'a> {
    fn on_game_start(&mut self, map_name: String, _map_geometry: MapGeometry) -> ReplayResult<()> {
        self.map_name = Some(map_name);
        Ok(())
    }

    fn on_update(&mut self, update: &Update) -> ReplayResult<()> {
        self.current_tick = update.time.unwrap_or_default() as usize;

        // Iterate over planes
        for obj in update.objects.iter() {
            let is_plane = obj.r#type.map(|v| v < 5).unwrap_or(false);
            if !is_plane {
                continue;
            }

            let player_id = PlayerId(obj.owner());
            self.on_plane(player_id, obj)?;
        }

        Ok(())
    }

    fn on_event(&mut self, event: &GameEvent) -> ReplayResult<()> {
        match &event.event {
            Some(Event::Chat(chat)) => {
                let player_id = PlayerId(chat.sender());
                let player_key = self.get_player_key(player_id).unwrap_or(PlayerKey(0));
                self.conn.appender("chat")?.append_row(params![
                    self.replay_key,
                    self.current_tick,
                    player_key.0,
                    chat.message()
                ])?;
            }
            Some(Event::Goal(goal)) => {
                if goal.who_scored.len() > 0 {
                    let player_id = PlayerId(goal.who_scored[0]);
                    let player_key = self.get_player_key(player_id)?;
                    self.conn
                        .appender("goals")?
                        .append_row(params![self.replay_key, player_key.0])?;
                }
            }
            Some(Event::Kill(kill)) => {
                let who_killed = self
                    .get_player_key(PlayerId(kill.who_killed()))
                    .unwrap_or(PlayerKey(0));
                let who_died = self.get_player_key(PlayerId(kill.who_died()))?;
                self.conn.appender("kills")?.append_row(params![
                    self.current_tick,
                    self.replay_key,
                    who_killed.0,
                    who_died.0
                ])?;
            }
            Some(Event::SetPlayer(data)) => {
                self.on_set_player(data)?;
            }
            Some(Event::RemovePlayer(data)) => {
                self.on_remove_player(data)?;
            }
            _ => {}
        }
        Ok(())
    }
}

fn index_replay(
    conn: &Connection,
    path: &PathBuf,
    dump: bool,
    replay_key: u32,
    datetime: Option<DateTime<chrono::FixedOffset>>,
) -> Result<()> {
    let path_str: &str = &path.to_string_lossy().to_string();

    // Walk through replay
    let mut listener = IndexingListener::new(replay_key, conn, dump);
    alti_reader::replay::from_path(path, &mut listener)?;
    listener.write_buffered(true)?;
    listener.write_players()?;

    let map_name = listener
        .map_name
        .ok_or_else(|| anyhow!("No map name found in replay"))?;

    // Add record
    conn.execute(
        "INSERT INTO replays (key, path, map, ticks, datetime, dumped)
         VALUES (?, ?, ?, ?, ?, ?)",
        params![
            replay_key,
            path_str,
            map_name,
            listener.current_tick,
            datetime.map(|dt| dt.to_rfc3339().to_string()),
            dump,
        ],
    )?;
    Ok(())
}

fn collect_replay_paths(dir: &PathBuf, limit: Option<usize>) -> Result<Vec<std::path::PathBuf>> {
    let mut paths: Vec<_> = WalkDir::new(dir)
        .follow_links(true)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| e.path().extension().and_then(|s| s.to_str()) == Some("gz"))
        .map(|e| e.path().to_owned())
        .collect();

    if let Some(limit) = limit {
        paths.truncate(limit);
    }

    Ok(paths)
}

fn get_paths(args: &Args) -> Result<Vec<PathBuf>> {
    if args.stdin {
        let stdin = io::stdin();
        let mut paths: Vec<PathBuf> = stdin
            .lock()
            .lines()
            .filter_map(|line| line.ok())
            .map(PathBuf::from)
            .collect();

        if let Some(limit) = args.limit {
            paths.truncate(limit);
        }
        return Ok(paths);
    } else if let Some(replay_dir) = &args.replays {
        return collect_replay_paths(&replay_dir, args.limit);
    } else {
        return Err(anyhow!("Must specify either --replays or --stdin"));
    };
}

fn filter_paths(args: &Args, conn: &Connection, paths: Vec<PathBuf>) -> Result<Vec<PathBuf>> {
    conn.execute_batch(
        "
        CREATE TEMP TABLE temp_paths (
            path VARCHAR PRIMARY KEY
        )
    ",
    )?;

    {
        let mut app = conn.appender("temp_paths")?;
        for path in &paths {
            app.append_row([path.to_string_lossy()])?;
        }
    }

    let sql = "
        SELECT temp_paths.path
        FROM temp_paths
        LEFT JOIN replays ON temp_paths.path = replays.path
        WHERE replays.path IS NULL
        OR (? AND NOT replays.dumped)
    ";

    let mut stmt = conn.prepare(sql)?;
    let paths: Vec<PathBuf> = stmt
        .query_map(params![args.dump], |row| {
            let path_str: String = row.get(0)?;
            Ok(PathBuf::from(path_str))
        })?
        .filter_map(|r| r.ok())
        .collect();

    // Clean up
    conn.execute_batch("DROP TABLE temp_paths")?;

    Ok(paths)
}

fn main() -> Result<()> {
    let args: Args = Args::parse();
    let conn = Connection::open(&args.out)?;

    // Collect replay paths
    let all_paths = get_paths(&args)?;
    let paths = filter_paths(&args, &conn, all_paths)?;

    // Create progress bar
    let pb = if args.progress {
        let pb = ProgressBar::new(paths.len() as u64);
        pb.set_style(ProgressStyle::default_bar()
            .template("{spinner:.green} [{elapsed_precise}] [{bar:40.cyan/blue}] {pos}/{len} ({eta}) {msg}")
            .unwrap()
            .progress_chars("#>-"));
        Some(pb)
    } else {
        None
    };

    // Process replays
    for path in paths {
        let replay_key: u32 =
            conn.query_row("SELECT nextval('replay_keys')", [], |row| row.get(0))?;

        let datetime: Option<DateTime<chrono::FixedOffset>> = path
            .file_name()
            .and_then(|name| name.to_str())
            .and_then(|name| {
                DateTime::parse_from_str(&format!("{}+0000", &name[..19]), "%Y_%m_%dT%H_%M_%S%z")
                    .ok()
            });

        let result = index_replay(&conn, &path, args.dump, replay_key, datetime);
        if let Err(e) = result {
            eprintln!("{} (from {})", &e, path.display());
        }
        if let Some(pb) = &pb {
            pb.set_message(format!(
                "Last: {}",
                path.file_name().unwrap().to_string_lossy()
            ));
            pb.inc(1);
        }
    }

    if let Some(pb) = pb {
        pb.finish_and_clear();
    }

    Ok(())
}
