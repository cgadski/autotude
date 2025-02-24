pub mod proto {
    include!(concat!(env!("OUT_DIR"), "/_.rs"));
}
pub mod listener;
pub mod replay;

use indicatif::{ProgressBar, ProgressStyle};
pub use listener::{IndexingListener, ReplayState};

use anyhow::{anyhow, Result};
use chrono::DateTime;
use std::path::PathBuf;
use walkdir::WalkDir;

pub fn collect_replay_paths(dir: &PathBuf) -> Vec<std::path::PathBuf> {
    let paths: Vec<_> = WalkDir::new(dir)
        .follow_links(true)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| e.path().extension().and_then(|s| s.to_str()) == Some("pb"))
        .map(|e| e.path().to_owned())
        .collect();

    paths
}

// Expects a timestamp of the form %Y_%m_%dT%H_%M_%SZ in GMT+0, like 2024_13_13T10_10_10Z
pub fn parse_datetime(s: &str) -> Option<DateTime<chrono::FixedOffset>> {
    if s.len() >= 19 {
        DateTime::parse_from_str(&format!("{}+0000", &s[..19]), "%Y_%m_%dT%H_%M_%S%z").ok()
    } else {
        None
    }
}

pub fn get_stem(path: &PathBuf) -> Result<String> {
    Ok(path
        .file_stem()
        .ok_or_else(|| anyhow!("Couldn't read stem on path {:?}", path))?
        .to_string_lossy()
        .to_string())
}

pub fn make_pb(size: usize) -> ProgressBar {
    let pb = ProgressBar::new(size as u64);
    pb.set_style(ProgressStyle::default_bar()
                    .template("{spinner:.green} [{elapsed_precise}] [{bar:40.cyan/blue}] {pos}/{len} ({eta}) {msg}")
                    .unwrap()
                    .progress_chars("#>-"));
    pb
}
