use alti_reader::make_pb;
use alti_reader::proto::{GameEvent, Update};
use alti_reader::replay::{read_replay_file, ReplayListener, Result};
use clap::Parser;
use flate2::{write::GzEncoder, Compression};
use prost::alloc::vec::Vec;
use prost::Message;
use std::{
    fs::{self, File},
    io::{BufWriter, Write},
    path::Path,
};
use threadpool::ThreadPool;
use walkdir::WalkDir;

#[derive(Parser)]
#[command()]
struct Args {
    input: String,
    output: String,
    #[arg(short, long, default_value_t = 4)]
    workers: usize,
}

struct VacuumListener {
    queued_update: Option<Update>,
    duration: u64,
    encoder: GzEncoder<BufWriter<File>>,
}

impl VacuumListener {
    fn new(path: &str) -> Result<Self> {
        let file = File::create(path)?;
        let writer = BufWriter::new(file);
        let encoder = GzEncoder::new(writer, Compression::default());
        Ok(Self {
            queued_update: None,
            duration: 0,
            encoder: encoder,
        })
    }

    fn finish(mut self) -> Result<()> {
        if let Some(mut queued) = self.queued_update.take() {
            queued.time = None;
            queued.duration = Some(self.duration);
            self.write_update(&queued)?;
        }

        self.encoder.finish()?;
        Ok(())
    }

    fn write_update(&mut self, update: &Update) -> Result<()> {
        let mut buf = Vec::with_capacity(update.encoded_len() + 4);
        update.encode_length_delimited(&mut buf)?;
        self.encoder.write_all(&buf)?;
        Ok(())
    }
}

impl ReplayListener for VacuumListener {
    fn on_event(&mut self, _event: &GameEvent) -> Result<()> {
        Ok(())
    }

    fn on_update(&mut self, update: &Update) -> Result<()> {
        self.duration += 1;

        let Some(mut queued) = self.queued_update.take() else {
            self.queued_update = Some(update.clone());
            return Ok(());
        };

        let objects_changed = update.objects != queued.objects;
        let has_events = !update.events.is_empty();

        if objects_changed || has_events {
            queued.time = None;
            queued.duration = Some(self.duration);
            self.write_update(&queued)?;
            self.duration = 0;
            self.queued_update = Some(update.clone());
            Ok(())
        } else {
            self.queued_update = Some(queued);
            Ok(())
        }
    }
}

fn vacuum(input: &str, output: &str) -> Result<()> {
    let mut listener = VacuumListener::new(output)?;
    read_replay_file(input, &mut listener)?;
    listener.finish()
}

fn main() -> Result<()> {
    let args = Args::parse();
    let out_dir = Path::new(&args.output);
    fs::create_dir_all(out_dir)?;

    let entries: std::vec::Vec<_> = WalkDir::new(&args.input)
        .min_depth(1)
        .max_depth(1)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| e.file_type().is_file())
        .collect();

    let pb = make_pb(entries.len());
    let pool = ThreadPool::new(args.workers);
    for entry in entries {
        let pb = pb.clone();
        let out_path = out_dir.join(entry.file_name());
        pool.execute(move || {
            let input = entry.path().to_str().unwrap().to_owned();
            let output = out_path.to_str().unwrap().to_owned();
            if let Err(e) = vacuum(&input, &output) {
                pb.println(format!("Error processing {}: {:#}", input, e));
                if let Err(rm_err) = std::fs::remove_file(&out_path) {
                    pb.println(format!("Failed to remove {}: {:#}", output, rm_err));
                }
            }
            pb.inc(1);
        });
    }
    pool.join();
    pb.finish_with_message("done");

    Ok(())
}
