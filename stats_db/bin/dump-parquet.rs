use alti_reader::listener::{IndexingListener, PlayerId, PlayerKey, PlayerServerPresence};
use alti_reader::make_pb;
use alti_reader::proto::{GameEvent, GameObject, ObjectType, Update};
use alti_reader::replay::{read_replay_file, ReplayListener, Result as ReplayResult};
use anyhow::{anyhow, Result};
use arrow::array::{ArrayRef, Int32Array, UInt32Array};
use arrow::record_batch::RecordBatch;
use clap::Parser;
use sqlite::State;
use std::collections::HashMap;
use std::env;
use std::fs::File;
use std::path::PathBuf;
use std::sync::Arc;

use arrow::datatypes::{DataType, Field, Schema};
use parquet::arrow::ArrowWriter;
use parquet::file::properties::WriterProperties;

#[derive(Parser, Debug)]
struct Args {
    #[arg(short, long, help = "Output parquet file path")]
    output: PathBuf,
}

#[derive(Debug, Clone, Copy, Default)]
struct PlayerRow {
    x: u32,
    y: u32,
    angle: u32,
    handle_key: i32,
}

#[derive(Debug, Clone, Copy)]
struct BallRow {
    x: u32,
    y: u32,
    team: u32,
}

#[derive(Debug, Clone)]
struct GameRow {
    replay_key: u32,
    tick: u32,
    ball: Option<BallRow>,
    players: [Option<PlayerRow>; 8],
}

impl GameRow {
    fn new() -> Self {
        GameRow {
            replay_key: 0,
            tick: 0,
            ball: None,
            players: [None; 8],
        }
    }
}

struct GameTracker {
    indexer: IndexingListener,
    replay_key: u32,
    current_row: GameRow,
    rows: Vec<GameRow>,
    player_key_to_handle: HashMap<i32, i32>,
    player_key_to_slot: HashMap<i32, usize>,
}

impl GameTracker {
    fn new(
        replay_key: u32,
        player_key_to_handle: HashMap<i32, i32>,
        player_key_to_team: HashMap<i32, u32>,
    ) -> Self {
        let mut player_key_to_slot = HashMap::new();

        let mut team3_handles = Vec::new();
        let mut team4_handles = Vec::new();

        for (&player_key, &team) in &player_key_to_team {
            if let Some(&handle_key) = player_key_to_handle.get(&player_key) {
                if team == 3 {
                    team3_handles.push((handle_key, player_key));
                } else if team == 4 {
                    team4_handles.push((handle_key, player_key));
                }
            }
        }

        team3_handles.sort();
        team3_handles.dedup();
        team4_handles.sort();
        team4_handles.dedup();

        for (i, &(_handle_key, player_key)) in team3_handles.iter().take(4).enumerate() {
            player_key_to_slot.insert(player_key, i);
        }

        for (i, &(_handle_key, player_key)) in team4_handles.iter().take(4).enumerate() {
            player_key_to_slot.insert(player_key, i + 4);
        }

        Self {
            indexer: IndexingListener::new(),
            replay_key,
            current_row: GameRow::new(),
            rows: Vec::new(),
            player_key_to_handle,
            player_key_to_slot,
        }
    }
}

impl GameTracker {
    fn handle_plane(&mut self, obj: &GameObject, player_key: PlayerKey) {
        let x = obj.position_x();
        let y = obj.position_y();
        let angle = obj.angle();

        if let Some(&slot) = self.player_key_to_slot.get(&player_key.0) {
            if let Some(&handle_key) = self.player_key_to_handle.get(&player_key.0) {
                self.current_row.players[slot] = Some(PlayerRow {
                    x,
                    y,
                    angle,
                    handle_key,
                });
            }
        }

        if obj.powerup() == ObjectType::Ball {
            self.current_row.ball = Some(BallRow {
                x,
                y,
                team: obj.team() as u32,
            });
        }
    }
}

impl ReplayListener for GameTracker {
    // fn on_start_frame(&mut self) -> ReplayResult<()> {
    //     self.current_row = GameRow::new();
    //     Ok(())
    // }

    fn on_event(&mut self, event: &GameEvent) -> ReplayResult<()> {
        self.indexer.on_event(event)?;
        Ok(())
    }

    fn on_update(&mut self, update: &Update) -> ReplayResult<()> {
        self.indexer.on_update(update)?;

        {
            let row = &mut self.current_row;
            row.tick = self.indexer.state.current_tick as u32;
            row.replay_key = self.replay_key;
            row.ball = None;
            row.players = [None; 8];
        }

        for obj in update.objects.iter() {
            let is_plane = (obj.r#type() as u32) < 5;
            if is_plane {
                let player_id: PlayerId = obj.owner().into();
                if let Ok(PlayerServerPresence::Present(player_key)) =
                    self.indexer.get_player_key(player_id)
                {
                    self.handle_plane(obj, player_key);
                }
            }

            if obj.r#type() == ObjectType::Ball {
                self.current_row.ball = Some(BallRow {
                    x: obj.position_x(),
                    y: obj.position_y(),
                    team: 0,
                });
            }
        }

        self.rows.push(self.current_row.clone());

        Ok(())
    }
}

fn write_batch(
    writer: &mut ArrowWriter<File>,
    schema: Arc<Schema>,
    records: &[GameRow],
) -> Result<()> {
    if records.is_empty() {
        return Ok(());
    }

    macro_rules! col {
        ($ty:ty, $map:expr) => {
            Arc::new(<$ty>::from_iter(records.iter().map($map))) as ArrayRef
        };
    }

    let mut arrays = vec![
        col!(UInt32Array, |r| r.replay_key),
        col!(UInt32Array, |r| r.tick),
        col!(UInt32Array, |r| r.ball.map(|b| b.x)),
        col!(UInt32Array, |r| r.ball.map(|b| b.y)),
        col!(UInt32Array, |r| r.ball.map(|b| b.team)),
    ];

    for i in 0..8 {
        arrays.push(col!(UInt32Array, |r| r.players[i].map(|p| p.x)));
        arrays.push(col!(UInt32Array, |r| r.players[i].map(|p| p.y)));
        arrays.push(col!(UInt32Array, |r| r.players[i].map(|p| p.angle)));
        arrays.push(col!(Int32Array, |r| r.players[i].map(|p| p.handle_key)));
    }

    let batch = RecordBatch::try_new(schema, arrays)?;
    writer.write(&batch)?;
    Ok(())
}

fn main() -> Result<()> {
    let args = Args::parse();

    let replay_dir =
        env::var("REPLAY_DIR").map_err(|_| anyhow!("REPLAY_DIR environment variable not set"))?;
    let replay_base = PathBuf::from(&replay_dir);

    let stats_db =
        env::var("STATS_DB").map_err(|_| anyhow!("STATS_DB environment variable not set"))?;
    let conn = sqlite::Connection::open(&stats_db)?;

    let query =
        "SELECT stem, replay_key FROM ladder_games NATURAL JOIN replays ORDER BY started_at DESC LIMIT 1000";
    let mut stmt = conn.prepare(query)?;

    let mut replays = Vec::new();
    while let State::Row = stmt.next()? {
        if let (Ok(stem), Ok(replay_key)) = (stmt.read::<String, _>(0), stmt.read::<i64, _>(1)) {
            replays.push((stem, replay_key));
        }
    }

    let mut schema_fields = vec![
        Field::new("replay_key", DataType::UInt32, false),
        Field::new("tick", DataType::UInt32, false),
        Field::new("ball_x", DataType::UInt32, true),
        Field::new("ball_y", DataType::UInt32, true),
        Field::new("ball_team", DataType::UInt32, true),
    ];

    for i in 0..8 {
        schema_fields.push(Field::new(&format!("p{}_x", i), DataType::UInt32, true));
        schema_fields.push(Field::new(&format!("p{}_y", i), DataType::UInt32, true));
        schema_fields.push(Field::new(&format!("p{}_angle", i), DataType::UInt32, true));
        schema_fields.push(Field::new(&format!("p{}_handle", i), DataType::Int32, true));
    }

    let schema = Arc::new(Schema::new(schema_fields));

    let file = File::create(&args.output)?;
    let props = WriterProperties::builder().build();
    let mut writer = ArrowWriter::try_new(file, schema.clone(), Some(props))?;

    let pb = make_pb(replays.len());
    let mut processed = 0;
    let mut total_rows = 0;

    for (stem, replay_key) in replays {
        let replay_path = replay_base.join(format!("{}.pb", stem));

        let player_query =
            "SELECT player_key, handle_key, team FROM player_key_handle NATURAL JOIN players WHERE replay_key = ?";
        let mut player_stmt = conn.prepare(player_query)?;
        player_stmt.bind((1, replay_key))?;

        let mut player_key_to_handle = HashMap::new();
        let mut player_key_to_team = HashMap::new();
        while let State::Row = player_stmt.next()? {
            if let (Ok(player_key), Ok(handle_key), Ok(team)) = (
                player_stmt.read::<i64, _>(0),
                player_stmt.read::<i64, _>(1),
                player_stmt.read::<i64, _>(2),
            ) {
                player_key_to_handle.insert(player_key as i32, handle_key as i32);
                player_key_to_team.insert(player_key as i32, team as u32);
            }
        }

        let mut tracker =
            GameTracker::new(replay_key as u32, player_key_to_handle, player_key_to_team);
        match read_replay_file(&replay_path, &mut tracker) {
            Ok(()) => {
                let new_rows = tracker.rows.len();
                write_batch(&mut writer, schema.clone(), &tracker.rows)?;
                total_rows += new_rows;
                processed += 1;
                pb.set_message(format!(
                    "Processed {} replays, {} rows",
                    processed, total_rows
                ));
            }
            Err(e) => {
                panic!("{}: error reading replay: {}", stem, e);
            }
        }
        pb.inc(1);
    }

    writer.close()?;

    pb.finish_with_message(format!(
        "Complete. Processed {} replays, {} records total",
        processed, total_rows
    ));

    println!("Wrote {} records to {:?}", total_rows, args.output);

    Ok(())
}
