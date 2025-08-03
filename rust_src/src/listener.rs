use crate::listener::state_timeline::{ConflictingDataError, StateTimeline};
use crate::proto::game_event::Event;
use crate::proto::{GameEvent, GameObject, ObjectType, RemovePlayerEvent, SetPlayerEvent, Update};
use crate::replay::{ReplayListener, Result as ReplayResult};
use anyhow::{anyhow, bail, Result};
use chrono::DateTime;
use std::collections::HashMap;

mod state_timeline;

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

#[derive(Debug, Clone, Copy, Hash, Eq, PartialEq)]
pub struct Loadout {
    pub plane: i32,
    pub red_perk: i32,
    pub green_perk: Option<i32>,
    pub blue_perk: Option<i32>,
}

#[derive(Debug, Clone, Copy, Hash, Eq, PartialEq)]
pub struct LoadoutState {
    pub data: Loadout,
    pub start_tick: i32,
    pub ticks_alive: i32,
}

#[derive(Default, Debug, Clone, Copy, Hash, Eq, PartialEq)]
pub struct Liveness {
    pub is_alive: bool,
}

#[derive(Debug)]
pub struct PlayerState {
    pub key: PlayerKey,
    pub data: SetPlayerEvent,
    pub team: i32,
    pub nick: String,
    pub ticks_alive: i32,
    pub spawns: StateTimeline<Liveness>,
    pub loadout_history: Vec<LoadoutState>,
}

#[derive(Debug, Clone, Copy, Hash, Eq, PartialEq)]
pub enum Ball {
    Possessed { player: PlayerKey },
    Loose { x: i32, y: i32 },
}

pub struct ReplayState {
    pub server_name: Option<String>,
    pub datetime: Option<DateTime<chrono::FixedOffset>>,
    pub map_name: Option<String>,
    pub current_tick: usize,
    pub player_states: HashMap<PlayerKey, PlayerState>,
    pub ball: StateTimeline<Option<Ball>>,
}

impl ReplayState {
    pub fn new() -> Self {
        Self {
            server_name: None,
            datetime: None,
            map_name: None,
            current_tick: 0,
            player_states: HashMap::new(),
            ball: Default::default(),
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

    fn adapt_loadout(plane: &GameObject) -> Loadout {
        Loadout {
            plane: plane.r#type() as i32,
            red_perk: plane.red_perk() as i32,
            green_perk: plane.green_perk as Option<i32>,
            blue_perk: plane.blue_perk as Option<i32>,
        }
    }

    fn on_plane(&mut self, id: PlayerId, plane: &GameObject) -> Result<()> {
        let player_key = self.get_player_key(id)?;
        if let Some(state) = self.state.player_states.get_mut(&player_key) {
            state.ticks_alive += 1;
            let team = plane.team();
            if team > 2 {
                state.team = team as i32;
            }
            state.spawns.set(Liveness { is_alive: true })?;
            if plane.powerup() == ObjectType::Ball {
                self.state
                    .ball
                    .set(Some(Ball::Possessed { player: player_key }))
                    .map_err(|err| anyhow!(err).context("Bad premise: multiple balls???"))?;
            }
            let next_loadout = Self::adapt_loadout(plane);
            let prev_loadout_state = state.loadout_history.last();
            // if loadout changed, push new loadout state
            if prev_loadout_state.is_none_or(|prev| prev.data != next_loadout) {
                let new_loadout_state = LoadoutState {
                    data: next_loadout,
                    start_tick: self.state.current_tick as i32,
                    ticks_alive: 0,
                };
                state.loadout_history.push(new_loadout_state);
            }
            // unwrap: we already checked and pushed to `loadout_history` via `if` above
            state.loadout_history.last_mut().unwrap().ticks_alive += 1;
        }

        Ok(())
    }

    fn on_ball(&mut self, ball: &GameObject) -> Result<()> {
        if ball.position_x.is_none() || ball.position_y.is_none() {
            bail!("Bad premise: ball object had no position: {:?}", ball)
        }
        let ball = Ball::Loose {
            x: ball.position_x() as i32,
            y: ball.position_y() as i32,
        };
        match self.state.ball.set(Some(ball)) {
            Ok(()) => Ok(()),
            Err(ConflictingDataError) => {
                // multiple ball objects have been observed for a tick when the round is
                // forcibly ended (overtime) exactly when a ball is lost, i think. whatever,
                // just ignore the error and leave it undefined which is used
                Ok(())
            }
        }
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
                spawns: Default::default(),
                loadout_history: Vec::new(),
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

        let tick = self.state.current_tick as i32;
        for player in self.state.player_states.values_mut() {
            player.spawns.end_tick(tick);
        }
        self.state.ball.end_tick(tick);

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
