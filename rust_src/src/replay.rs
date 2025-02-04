use anyhow::Result;
use flate2::read::GzDecoder;
use prost::Message;
use std::collections::HashMap;
use std::fs::File;
use std::io::Read;
use std::path::Path;

use crate::proto::game_event::Event;
use crate::proto::{MapGeometry, Update};

#[derive(Debug, Clone)]
pub struct Player {
    pub name: String,
    pub team: i32,
}

pub trait ReplayListener {
    fn on_game_start(&mut self, map_name: String, map_geometry: MapGeometry);
    fn on_update(&mut self, update: &Update, players: &HashMap<i32, Player>);
}

struct ReaderState {
    players: HashMap<i32, Player>,
}

fn on_event<L: ReplayListener>(event: &Event, state: &mut ReaderState, listener: &mut L) {
    match event {
        Event::MapLoad(map_load) => {
            if let (Some(geom), Some(name)) = (&map_load.map, &map_load.name) {
                listener.on_game_start(name.clone(), geom.clone());
            }
        }
        Event::SetPlayer(set_player) => {
            if let (Some(id), Some(name), Some(team)) =
                (set_player.id, &set_player.name, set_player.team)
            {
                state.players.insert(
                    id as i32,
                    Player {
                        name: name.clone(),
                        team: team as i32,
                    },
                );
            }
        }
        Event::RemovePlayer(remove_player) => {
            if let Some(id) = remove_player.id {
                state.players.remove(&(id as i32));
            }
        }
        _ => {}
    }
}

pub fn from_path<P: AsRef<Path>, L: ReplayListener>(path: P, listener: &mut L) -> Result<()> {
    let mut file = File::open(path)?;
    let mut compressed = Vec::new();
    file.read_to_end(&mut compressed)?;

    let mut decoder = GzDecoder::new(&compressed[..]);
    let mut decompressed = Vec::new();
    decoder.read_to_end(&mut decompressed)?;

    let mut state = ReaderState {
        players: HashMap::new(),
    };

    let mut buf = &decompressed[..];
    while !buf.is_empty() {
        let len = prost::decode_length_delimiter(buf)?;
        let msg_bytes = &buf[prost::length_delimiter_len(len)..][..len];
        let update = Update::decode(msg_bytes)?;

        buf = &buf[prost::length_delimiter_len(len) + len..];

        for opt_event in &update.events {
            if let Some(ref event) = opt_event.event {
                on_event(&event, &mut state, listener);
            }
        }

        listener.on_update(&update, &state.players);
    }

    Ok(())
}
