use flate2::read::GzDecoder;
use prost::Message;
use std::fs::File;
use std::io::Read;
use std::path::Path;

use crate::proto::{GameEvent, Update};

pub type Result<T> = std::result::Result<T, anyhow::Error>;

pub trait ReplayListener {
    fn on_update(&mut self, update: &Update) -> Result<()>;
    fn on_event(&mut self, event: &GameEvent) -> Result<()>;
}

pub fn read_replay_file<P: AsRef<Path>, L: ReplayListener>(
    path: P,
    listener: &mut L,
) -> Result<()> {
    let mut file = File::open(path)?;
    let mut compressed = Vec::new();
    file.read_to_end(&mut compressed)?;

    let mut decoder = GzDecoder::new(&compressed[..]);
    let mut decompressed = Vec::new();
    decoder.read_to_end(&mut decompressed)?;

    let mut buf = &decompressed[..];
    while !buf.is_empty() {
        let len = prost::decode_length_delimiter(buf)?;
        let msg_bytes = &buf[prost::length_delimiter_len(len)..][..len];
        let update = Update::decode(msg_bytes)?;

        buf = &buf[prost::length_delimiter_len(len) + len..];

        for opt_event in &update.events {
            listener.on_event(opt_event)?;
        }

        listener.on_update(&update)?;
    }

    Ok(())
}
