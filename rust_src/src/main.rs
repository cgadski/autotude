use alti_reader::proto::MapGeometry;
use alti_reader::proto::Update;
use alti_reader::replay::{Player, ReplayListener};
use anyhow::Result;
use std::collections::HashMap;

struct PrintingListener {
    update_count: usize,
    final_players: HashMap<i32, Player>,
}

impl PrintingListener {
    fn new() -> Self {
        Self {
            update_count: 0,
            final_players: HashMap::new(),
        }
    }
}

impl ReplayListener for PrintingListener {
    fn on_game_start(&mut self, map_name: String, _map_geometry: MapGeometry) {
        println!("Map: {}", map_name);
    }

    fn on_update(&mut self, _update: &Update, players: &HashMap<i32, Player>) {
        self.update_count += 1;
        self.final_players = players.clone();
    }
}

fn main() -> Result<()> {
    let args: Vec<String> = std::env::args().collect();
    if args.len() != 2 {
        println!("Usage: {} <replay.pb.gz>", args[0]);
        std::process::exit(1);
    }

    let mut listener = PrintingListener::new();
    alti_reader::replay::from_path(&args[1], &mut listener)?;

    println!("Updates: {}", listener.update_count);
    println!("Players:");
    for (id, player) in &listener.final_players {
        println!("  {}: {} (team {})", id, player.name, player.team);
    }

    Ok(())
}
