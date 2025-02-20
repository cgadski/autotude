pub mod proto {
    include!(concat!(env!("OUT_DIR"), "/_.rs"));
}
pub mod listener;
pub mod replay;

pub use listener::{IndexingListener, ReplayState};

use chrono::DateTime;

// Expects a timestamp of the form %Y_%m_%dT%H_%M_%SZ in GMT+0, like 2024_13_13T10_10_10Z
pub fn parse_datetime(s: &str) -> Option<DateTime<chrono::FixedOffset>> {
    if s.len() >= 19 {
        DateTime::parse_from_str(&format!("{}+0000", &s[..19]), "%Y_%m_%dT%H_%M_%S%z").ok()
    } else {
        None
    }
}
