use anyhow::Context;

use flate2::read::GzDecoder;
use prost::Message;
use std::fs::File;
use std::io::{BufReader, Read};
use std::path::Path;

use crate::proto::{GameEvent, Update};

pub type Result<T> = std::result::Result<T, anyhow::Error>;

pub trait ReplayListener {
    fn on_start_frame(&mut self) -> Result<()> {
        Ok(())
    }
    fn on_event(&mut self, event: &GameEvent) -> Result<()>;
    fn on_update(&mut self, update: &Update) -> Result<()>;
}

pub fn read_replay_file<P: AsRef<Path>, L: ReplayListener>(
    path: P,
    listener: &mut L,
) -> Result<()> {
    let file = File::open(path)?;
    let buf_reader = BufReader::new(file);
    let mut decoder = GzDecoder::new(buf_reader);

    let mut buffer = Vec::new();
    let mut chunk = [0u8; 8192];

    loop {
        let bytes_read = decoder
            .read(&mut chunk)
            .with_context(|| "Error reading from compressed stream")?;

        if bytes_read == 0 {
            break;
        }

        buffer.extend_from_slice(&chunk[..bytes_read]);

        while buffer.len() >= prost::length_delimiter_len(1) {
            let mut buf = &buffer[..];
            let len_result = prost::decode_length_delimiter(&mut buf);
            let len = match len_result {
                Ok(len) => len,
                Err(_) => break,
            };

            let total_msg_len = prost::length_delimiter_len(len) + len;
            if buffer.len() < total_msg_len {
                break;
            }

            let msg_bytes = &buffer[prost::length_delimiter_len(len)..total_msg_len];
            let update =
                Update::decode(msg_bytes).with_context(|| "Error decoding protobuf update")?;

            listener.on_start_frame()?;

            for opt_event in &update.events {
                listener
                    .on_event(opt_event)
                    .with_context(|| format!("Error processing event: {:?}", opt_event))?;
            }

            listener
                .on_update(&update)
                .with_context(|| "Error processing update")?;

            buffer.drain(..total_msg_len);
        }
    }

    Ok(())
}
