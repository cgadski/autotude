use alti_reader::{
    make_pb,
    proto::{game_event::Event, GameEvent, ObjectType, Update},
    replay::{read_replay_file, ReplayListener},
};
use anyhow::{anyhow, Result};
use ndarray::Array1;
use ndarray_npy::NpzWriter;
use std::env;
use std::fs::File;
use std::io::{self, BufRead};
use std::path::PathBuf;

struct BallDumpListener {
    ball_active: Vec<i32>, // Using i32 instead of bool for NumPy compatibility
    ball_pos_x: Vec<i32>,
    ball_pos_y: Vec<i32>,
}

impl BallDumpListener {
    fn new() -> Self {
        Self {
            ball_active: Vec::new(),
            ball_pos_x: Vec::new(),
            ball_pos_y: Vec::new(),
        }
    }
}

impl ReplayListener for BallDumpListener {
    fn on_update(&mut self, update: &Update) -> Result<()> {
        let mut found_ball = false;

        for obj in &update.objects {
            if obj.r#type() == ObjectType::Ball {
                found_ball = true;
                self.ball_active.push(1);
                self.ball_pos_x.push(obj.position_x() as i32);
                self.ball_pos_y.push(obj.position_y() as i32);
                break;
            }
        }

        if !found_ball {
            self.ball_active.push(0);
            self.ball_pos_x.push(0);
            self.ball_pos_y.push(0);
        }

        Ok(())
    }

    fn on_event(&mut self, event: &GameEvent) -> Result<()> {
        match &event.event {
            Some(Event::Goal(_)) => {}
            _ => {}
        }
        Ok(())
    }
}

fn save_to_numpy(
    all_ball_active: Vec<i32>,
    all_ball_pos_x: Vec<i32>,
    all_ball_pos_y: Vec<i32>,
    output_path: &str,
) -> Result<()> {
    let ball_active_array = Array1::from(all_ball_active);
    let ball_pos_x_array = Array1::from(all_ball_pos_x);
    let ball_pos_y_array = Array1::from(all_ball_pos_y);

    let path = std::path::Path::new(output_path);
    let file = File::create(path).map_err(|e| anyhow!("Failed to create file: {}", e))?;
    let mut npz = NpzWriter::new(file);

    npz.add_array("ball_active", &ball_active_array)?;
    npz.add_array("ball_pos_x", &ball_pos_x_array)?;
    npz.add_array("ball_pos_y", &ball_pos_y_array)?;

    npz.finish()?;

    Ok(())
}

fn main() -> Result<()> {
    let replay_dir =
        env::var("REPLAY_DIR").map_err(|_| anyhow!("REPLAY_DIR environment variable not set"))?;
    let base_path = PathBuf::from(&replay_dir);
    eprintln!("Using replay directory: {}", replay_dir);

    let stdin = io::stdin();

    // Arrays to store all ball data
    let mut all_ball_active = Vec::new();
    let mut all_ball_pos_x = Vec::new();
    let mut all_ball_pos_y = Vec::new();

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
                all_ball_active.extend(listener.ball_active);
                all_ball_pos_x.extend(listener.ball_pos_x);
                all_ball_pos_y.extend(listener.ball_pos_y);

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

    // Save data to numpy file
    if !all_ball_active.is_empty() {
        println!("Saving ball data to numpy file...");
        save_to_numpy(
            all_ball_active,
            all_ball_pos_x,
            all_ball_pos_y,
            "ball_data.npz",
        )?;
    }

    Ok(())
}
