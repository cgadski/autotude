use alti_reader::listener::{PlayerKey, PlayerState};
use alti_reader::{collect_replay_paths, get_stem, make_pb, IndexingListener, ReplayState};
use anyhow::{anyhow, Result};
use chrono::DateTime;
use clap::Parser;
use csv;
use postgres::{Client, NoTls, Statement, Transaction};
use std::collections::HashMap;
use std::io::{self, BufRead};
use std::path::PathBuf;

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

struct Indexer {
    start_replay: Statement,
    finalize_replay: Statement,
}

impl Indexer {
    fn new(conn: &mut Client) -> Result<Self> {
        let start_replay = conn.prepare(
            "
            INSERT INTO replays_raw (stem, completed, status)
            VALUES ($1::varchar, false, 'Indexing in progress')
            RETURNING replay_key
        ",
        )?;
        let finalize_replay = conn.prepare("
            UPDATE replays_raw
            SET (stem, map, server, duration, started_at, completed, status)
            = ($2::varchar, $3::varchar, $4::varchar, $5::integer, $6::timestamp with time zone, true, '')
            WHERE replay_key = $1::integer
        ")?;
        Ok(Self {
            start_replay,
            finalize_replay,
        })
    }

    fn write_players(
        &self,
        conn: &mut Transaction,
        replay_key: i32,
        states: HashMap<PlayerKey, PlayerState>,
    ) -> Result<()> {
        let copy_stmt = "COPY players (replay_key, player_key, nick, vapor, level, ace, ticks_alive, team) FROM STDIN WITH (FORMAT csv)";
        let mut writer = conn.copy_in(copy_stmt)?;
        let mut csv_writer = csv::Writer::from_writer(&mut writer);

        for state in states.values() {
            csv_writer.write_record(&[
                replay_key.to_string(),
                state.key.0.to_string(),
                state.nick.clone(),
                state.data.vapor.clone().unwrap_or_default(),
                state.data.level.map(|v| v.to_string()).unwrap_or_default(),
                state
                    .data
                    .ace_rank
                    .map(|v| v.to_string())
                    .unwrap_or_default(),
                state.ticks_alive.to_string(),
                state.team.to_string(),
            ])?;
        }

        csv_writer.flush()?;
        drop(csv_writer);
        writer.finish()?;
        Ok(())
    }

    fn run<'a>(&self, conn: &'a mut Transaction, path: &PathBuf) -> Result<()> {
        let path_datetime: Option<DateTime<chrono::FixedOffset>> = path
            .file_name()
            .and_then(|name| alti_reader::parse_datetime(&name.to_string_lossy()));

        let path_stem: String = get_stem(path)?;

        let replay_key = conn
            .query_one(&self.start_replay, &[&path_stem])
            .map_err(|e| anyhow!("Failed to insert replay: {}", e))?
            .get(0);

        let state: ReplayState = {
            let mut listener = IndexingListener::new();
            alti_reader::replay::read_replay_file(path, &mut listener)?;
            listener.state
        };

        self.write_players(conn, replay_key, state.player_states)?;

        conn.execute(
            &self.finalize_replay,
            &[
                &replay_key,
                &path_stem,
                &state.map_name,
                &state.server_name,
                &(state.current_tick as i32),
                &state.datetime.or(path_datetime),
            ],
        )
        .map_err(|e| anyhow!("Failed to add replay summary: {}", e))?;

        Ok(())
    }
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
        return Ok(collect_replay_paths(&replay_dir));
    } else {
        return Err(anyhow!("Must specify either --replays or --stdin"));
    };
}

fn filter_paths(_args: &Args, conn: &mut Client, paths: &Vec<PathBuf>) -> Result<Vec<PathBuf>> {
    conn.execute(
        "CREATE TEMP TABLE temp_stems (
            stem VARCHAR PRIMARY KEY,
            path VARCHAR
        )",
        &[],
    )?;

    let copy_stmt = "COPY temp_stems (stem, path) FROM STDIN WITH (FORMAT csv)";
    {
        let mut writer = conn.copy_in(copy_stmt)?;
        let mut csv_writer = csv::Writer::from_writer(&mut writer);

        for path in paths {
            if let Ok(stem) = get_stem(path) {
                csv_writer.write_record(&[stem, path.to_string_lossy().to_string()])?;
            }
        }
        csv_writer.flush()?;
        drop(csv_writer);
        writer.finish()?;
    }

    let sql = "
        SELECT temp_stems.path
        FROM temp_stems
        LEFT JOIN replays ON temp_stems.stem = replays.stem
        WHERE replays.stem IS NULL
        OR NOT replays.completed
    ";

    let rows = conn
        .query(sql, &[])
        .map_err(|e| anyhow!("Failed to query temp_stems table: {}", e))?;
    let paths: Vec<PathBuf> = rows
        .iter()
        .map(|row| PathBuf::from(row.get::<_, String>(0)))
        .collect();

    conn.execute("DROP TABLE temp_stems", &[])?;

    Ok(paths)
}

fn main() -> Result<()> {
    let args: Args = Args::parse();
    let conn_str = args.out.to_string_lossy();
    let mut conn = Client::connect(&conn_str, NoTls)?;

    // Collect replay paths
    let all_paths = get_paths(&args)?;
    let paths = filter_paths(&args, &mut conn, &all_paths)?;

    println!("Total files: {}", all_paths.len());
    println!("Need index: {}", paths.len());

    // Create progress bar
    let pb = if args.progress {
        Some(make_pb(paths.len()))
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
