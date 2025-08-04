use alti_reader::{
    listener::PlayerId,
    make_pb,
    proto::{game_event::Event, GameEvent, ObjectType, Update},
    replay::{read_replay_file, ReplayListener},
    IndexingListener,
};
use anyhow::{anyhow, Result};
use ndarray::Array1;
use ndarray_npy::NpzWriter;
use std::env;
use std::fs::File;
use std::io::{self, BufRead};
use std::path::PathBuf;

struct BallDumpListener {
    ball_active: Vec<i32>,
    ball_pos_x: Vec<i32>,
    ball_pos_y: Vec<i32>,
    is_pro: Vec<i32>,
    idx: IndexingListener,
}

impl BallDumpListener {
    fn new() -> Self {
        Self {
            ball_active: Vec::new(),
            ball_pos_x: Vec::new(),
            ball_pos_y: Vec::new(),
            is_pro: Vec::new(),
            idx: IndexingListener::new(),
        }
    }
}

impl ReplayListener for BallDumpListener {
    fn on_update(&mut self, update: &Update) -> Result<()> {
        self.idx.on_update(update)?;

        let mut found_ball = false;
        let mut is_pro = false;

        for obj in &update.objects {
            if obj.r#type() == ObjectType::Ball {
                found_ball = true;
                self.ball_active.push(0);
                self.ball_pos_x.push(obj.position_x() as i32);
                self.ball_pos_y.push(obj.position_y() as i32);
                break;
            }

            if obj.powerup() == ObjectType::Ball {
                found_ball = true;
                self.ball_active.push(obj.team() as i32);
                self.ball_pos_x.push(obj.position_x() as i32);
                self.ball_pos_y.push(obj.position_y() as i32);

                let id = PlayerId(obj.owner());
                let key = self.idx.get_present_player_key(id)?;
                let nick: &String = &self.idx.state.player_states.get(&key).unwrap().nick;
                if nick == "XX2" || nick == "> <8).G(u)ss [-fu] <" {
                    is_pro = true;
                }
                break;
            }
        }

        if !found_ball {
            self.ball_active.push(-1);
            self.ball_pos_x.push(0);
            self.ball_pos_y.push(0);
        }

        self.is_pro.push(if is_pro { 1 } else { 0 });

        Ok(())
    }

    fn on_event(&mut self, event: &GameEvent) -> Result<()> {
        self.idx.on_event(event)?;

        match &event.event {
            Some(Event::Goal(_)) => {}
            _ => {}
        }
        Ok(())
    }
}

fn save_to_numpy(listener: BallDumpListener, output_path: &str) -> Result<()> {
    let path = std::path::Path::new(output_path);
    let file = File::create(path).map_err(|e| anyhow!("Failed to create file: {}", e))?;
    let mut npz = NpzWriter::new(file);

    npz.add_array("ball_active", &Array1::from(listener.ball_active))?;
    npz.add_array("ball_pos_x", &Array1::from(listener.ball_pos_x))?;
    npz.add_array("ball_pos_y", &Array1::from(listener.ball_pos_y))?;
    npz.add_array("is_pro", &Array1::from(listener.is_pro))?;

    npz.finish()?;

    Ok(())
}

fn main() -> Result<()> {
    let replay_dir =
        env::var("REPLAY_DIR").map_err(|_| anyhow!("REPLAY_DIR environment variable not set"))?;
    let base_path = PathBuf::from(&replay_dir);
    eprintln!("Using replay directory: {}", replay_dir);

    let stdin = io::stdin();

    let mut agg_listener = BallDumpListener::new();

    let lines: Vec<String> = stdin
        .lock()
        .lines()
        .filter_map(|line| line.ok())
        .filter(|line| !line.trim().is_empty())
        .collect();

    let pb = make_pb(lines.len());
    let mut processed_count = 0;

    for line in lines.into_iter() {
        let mut path = base_path.clone();
        path.push(format!("{}.pb", line));

        let mut listener = BallDumpListener::new();

        match read_replay_file(&path, &mut listener) {
            Ok(()) => {
                // Collect data from this replay
                agg_listener.ball_active.extend(listener.ball_active);
                agg_listener.ball_pos_x.extend(listener.ball_pos_x);
                agg_listener.ball_pos_y.extend(listener.ball_pos_y);
                agg_listener.is_pro.extend(listener.is_pro);

                processed_count += 1;
                pb.inc(1);
                pb.set_message(format!("Processed {} replays", processed_count));
            }
            Err(e) => {
                pb.set_message(format!("Error: {}", e));
                pb.inc(1);
            }
        }
    }

    pb.finish_with_message(format!("Complete. Processed {} replays", processed_count));

    println!("Saving ball data to numpy file...");
    save_to_numpy(agg_listener, "ball_data.npz")?;

    Ok(())
}
