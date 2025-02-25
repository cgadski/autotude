use crate::proto::game_event::Event;
use crate::proto::{GameEvent, GameObject, ObjectType, RemovePlayerEvent, SetPlayerEvent, Update};
use crate::replay::{ReplayListener, Result as ReplayResult};
use anyhow::{anyhow, Result};
use chrono::DateTime;
use std::collections::HashMap;

#[derive(Debug, Clone, Copy, Hash, Eq, PartialEq)]
pub struct PlayerId(pub u32);

#[derive(Debug, Clone, Copy, Hash, Eq, PartialEq)]
pub struct PlayerKey(pub i32);

// in-game player ID
impl From<u32> for PlayerId {
    fn from(id: u32) -> Self {
        PlayerId(id)
    }
}

// player key in database
impl From<i32> for PlayerKey {
    fn from(key: i32) -> Self {
        PlayerKey(key)
    }
}

#[derive(Debug)]
pub struct PlayerState {
    pub key: PlayerKey,
    pub data: SetPlayerEvent,
    pub team: i32,
    pub nick: String,
    pub ticks_alive: i32,
}

pub struct ReplayState {
    pub server_name: Option<String>,
    pub datetime: Option<DateTime<chrono::FixedOffset>>,
    pub map_name: Option<String>,
    pub current_tick: usize,
    pub player_states: HashMap<PlayerKey, PlayerState>,
}

impl ReplayState {
    pub fn new() -> Self {
        Self {
            server_name: None,
            datetime: None,
            map_name: None,
            current_tick: 0,
            player_states: HashMap::new(),
        }
    }
}

pub struct IndexingListener {
    pub state: ReplayState,

    // mapping from altitude player IDs to our database keys
    next_player_key: i32,
    pub id_to_key: HashMap<PlayerId, PlayerKey>,
}

impl IndexingListener {
    pub fn new() -> Self {
        Self {
            state: ReplayState::new(),
            next_player_key: 0,
            id_to_key: HashMap::new(),
        }
    }

    fn on_plane(&mut self, id: PlayerId, plane: &GameObject) -> Result<()> {
        let player_key = if let Ok(k) = self.get_player_key(id) {
            k
        } else {
            return Ok(());
        };

        if let Some(state) = self.state.player_states.get_mut(&player_key) {
            state.ticks_alive += 1;
            let team = plane.team();
            if team > 2 {
                state.team = team as i32;
            }
        }

        Ok(())
    }

    fn on_ball(&mut self, _ball: &GameObject) -> Result<()> {
        Ok(())
    }

    fn on_set_player(&mut self, data: &SetPlayerEvent) -> Result<()> {
        let id = PlayerId(data.id());

        // Start a new player record if no player was previously registered at this id
        if !self.id_to_key.contains_key(&id) {
            let name: &str = &data.name();

            let key = PlayerKey(self.next_player_key);
            self.next_player_key += 1;

            let state = PlayerState {
                key,
                nick: name.to_string(),
                data: data.clone(),
                team: 2, // spectator
                ticks_alive: 0,
            };

            self.id_to_key.insert(id, key);
            self.state.player_states.insert(key, state);
        }
        Ok(())
    }

    fn on_remove_player(&mut self, data: &RemovePlayerEvent) -> Result<()> {
        let id: PlayerId = PlayerId(data.id());
        self.id_to_key.remove(&id);
        Ok(())
    }

    pub fn get_player_key(&mut self, id: PlayerId) -> Result<PlayerKey> {
        self.id_to_key
            .get(&id)
            .ok_or_else(|| anyhow!("Unregistered player id used."))
            .map(|x| x.clone())
    }
}

impl ReplayListener for IndexingListener {
    fn on_update(&mut self, update: &Update) -> ReplayResult<()> {
        self.state.current_tick += 1;

        for obj in update.objects.iter() {
            let is_plane = obj.r#type.map(|v| v < 5).unwrap_or(false);
            if is_plane {
                let player_id = PlayerId(obj.owner());
                self.on_plane(player_id, obj)?;
            }

            if obj.r#type() == ObjectType::Ball {
                self.on_ball(obj)?;
            }
        }

        Ok(())
    }

    fn on_event(&mut self, event: &GameEvent) -> ReplayResult<()> {
        match &event.event {
            Some(Event::MapLoad(load)) => {
                self.state.map_name = load.name.as_ref().map(|x| x.to_string());
                self.state.server_name = load.server.clone();
                self.state.datetime = crate::parse_datetime(load.datetime());
            }
            Some(Event::Chat(_chat)) => {
                // let player_id = PlayerId(chat.sender());
                // let player_key = self.get_player_key(player_id).unwrap_or(PlayerKey(0));
                // let stmt = self.conn.prepare(
                //     "INSERT INTO chat (replay, tick, player, message)
                //      VALUES ($1, $2, $3, $4)",
                // )?;
                // self.conn
                //     .execute(
                //         &stmt,
                //         &[
                //             &self.replay_key,
                //             &(self.current_tick as i32),
                //             &player_key.0,
                //             &chat.message(),
                //         ],
                //     )
                //     .or_else(|_| Err(anyhow!("Couldn't append chat record.")))?;
            }
            Some(Event::Goal(_goal)) => {
                // if goal.who_scored.len() > 0 {
                //     let player_id = PlayerId(goal.who_scored[0]);
                //     let player_key = self.get_player_key(player_id)?;
                //     let stmt = self
                //         .conn
                //         .prepare("INSERT INTO goals (replay, who_scored) VALUES ($1, $2)")?;
                //     self.conn
                //         .execute(&stmt, &[&self.replay_key, &player_key.0])
                //         .or_else(|_| Err(anyhow!("Couldn't append goal record.")))?;
                // }
            }
            Some(Event::Kill(_kill)) => {
                // let who_killed = self
                //     .get_player_key(PlayerId(kill.who_killed()))
                //     .unwrap_or(PlayerKey(0));
                // let who_died = self.get_player_key(PlayerId(kill.who_died()))?;
                // let stmt = self.conn.prepare(
                //     "INSERT INTO kills (tick, replay, who_killed, who_died)
                //      VALUES ($1, $2, $3, $4)",
                // )?;
                // self.conn
                //     .execute(
                //         &stmt,
                //         &[
                //             &(self.current_tick as i32),
                //             &self.replay_key,
                //             &who_killed.0,
                //             &who_died.0,
                //         ],
                //     )
                //     .or_else(|_| Err(anyhow!("Couldn't append kill record.")))?;
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
