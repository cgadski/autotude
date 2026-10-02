use alti_reader::proto::{game_event::Event, GameEvent, Update};
use alti_reader::replay::{read_replay_file, ReplayListener, Result};
use alti_reader::IndexingListener;
use clap::Parser;
use flate2::{write::GzEncoder, Compression};
use prost::alloc::vec::Vec;
use prost::Message;
use std::{
    collections::HashMap,
    fs::File,
    io::{BufWriter, Write},
};

#[derive(Parser)]
#[command(about = "Extract a time slice from a replay file")]
struct Args {
    input: String,
    output: String,
    /// Start tick (inclusive)
    start: usize,
    /// End tick (exclusive)
    end: usize,
}

struct SliceListener {
    indexer: IndexingListener,
    encoder: GzEncoder<BufWriter<File>>,

    start: usize,
    end: usize,

    // raw preamble events accumulated before start tick
    map_load: Option<GameEvent>,
    players: HashMap<u32, GameEvent>, // player id -> last SetPlayer event

    preamble_written: bool,
}

impl SliceListener {
    fn new(path: &str, start: usize, end: usize) -> Result<Self> {
        let file = File::create(path)?;
        let writer = BufWriter::new(file);
        let encoder = GzEncoder::new(writer, Compression::default());
        Ok(Self {
            indexer: IndexingListener::new(),
            encoder,
            start,
            end,
            map_load: None,
            players: HashMap::new(),
            preamble_written: false,
        })
    }

    fn finish(self) -> Result<()> {
        self.encoder.finish()?;
        Ok(())
    }

    fn write_update(&mut self, update: &Update) -> Result<()> {
        let mut buf = Vec::with_capacity(update.encoded_len() + 4);
        update.encode_length_delimited(&mut buf)?;
        self.encoder.write_all(&buf)?;
        Ok(())
    }

    fn write_preamble(&mut self) -> Result<()> {
        let mut events = Vec::new();
        if let Some(ml) = self.map_load.take() {
            events.push(ml);
        }
        for ev in self.players.values() {
            events.push(ev.clone());
        }
        let preamble = Update {
            time: None,
            duration: Some(0),
            objects: Vec::new(),
            events,
        };
        self.write_update(&preamble)
    }
}

impl ReplayListener for SliceListener {
    fn on_event(&mut self, event: &GameEvent) -> Result<()> {
        self.indexer.on_event(event)?;

        match &event.event {
            Some(Event::MapLoad(_)) => {
                self.map_load = Some(event.clone());
            }
            Some(Event::SetPlayer(sp)) => {
                self.players.insert(sp.id(), event.clone());
            }
            Some(Event::RemovePlayer(rp)) => {
                self.players.remove(&rp.id());
            }
            _ => {}
        }
        Ok(())
    }

    fn on_update(&mut self, update: &Update) -> Result<()> {
        self.indexer.on_update(update)?;

        let tick = self.indexer.state.current_tick;

        if tick >= self.end {
            return Ok(());
        }
        if tick < self.start {
            return Ok(());
        }

        if !self.preamble_written {
            self.write_preamble()?;
            self.preamble_written = true;
        }

        self.write_update(&update)
    }
}

fn main() -> Result<()> {
    let args = Args::parse();
    let mut listener = SliceListener::new(&args.output, args.start, args.end)?;
    read_replay_file(&args.input, &mut listener)?;
    listener.finish()
}
