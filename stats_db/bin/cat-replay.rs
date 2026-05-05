use alti_reader::proto::{GameEvent, Update};
use alti_reader::replay::{read_replay_file, ReplayListener, Result};
use clap::Parser;

#[derive(Parser)]
#[command()]
struct Args {
    path: String,
    #[arg(short, long)]
    objects: bool,
}

struct CatListener {
    objects: bool,
}

impl CatListener {
    fn new(objects: bool) -> Self {
        Self { objects }
    }
}

impl ReplayListener for CatListener {
    fn on_update(&mut self, update: &Update) -> Result<()> {
        if !update.events.is_empty() || self.objects {
            println!("update (dur = {})", update.duration());
        }

        for event in &update.events {
            println!(" > {:?}", event);
        }

        if self.objects {
            for obj in &update.objects {
                println!(" > {:?}", obj);
            }
        }

        Ok(())
    }
}

fn main() -> Result<()> {
    let args = Args::parse();
    let mut listener = CatListener::new(args.objects);
    read_replay_file(&args.path, &mut listener)
}
