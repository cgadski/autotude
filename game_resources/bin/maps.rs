//! Extracts map artwork from Altitude's .altx map archives for the replay
//! viewer: JPEG tiles (as stored by the game), alpha masks as greyscale PNGs,
//! and a map.json describing how to place the images.
//!
//! Usage: maps <out dir> [map names...]   (all maps by default)
//!
//! Reads alti_home/maps, the maps an Altitude client downloaded from servers
//! (on Windows, %LOCALAPPDATA%\NimblyGames\Altitude\maps\download) and any
//! directories listed in $ALTI_MAP_DIRS (separated like PATH).

use anyhow::{Context, Result};
use game_resources::{
    attr_f64, children, clean_dir, read_archive, read_textured_poly, version, Pages, TexturedPoly,
};
use rayon::prelude::*;
use serde::Serialize;
use std::collections::BTreeMap;
use std::path::{Path, PathBuf};
use std::{env, fs};

const IMAGE_ROOT: &str = "_derived/dist/.image/";

#[derive(Serialize)]
struct Item {
    #[serde(flatten)]
    poly: TexturedPoly,
    layer: i32,
    x: f64,
    y: f64,
    rotation: f64,
}

#[derive(Serialize)]
struct View {
    name: String,
    w: i32,
    h: i32,
    items: Vec<Item>,
}

#[derive(Serialize)]
struct MapArt<'a> {
    version: &'a str,
    level: String,
    background: i32,
    pages: &'a [game_resources::Page],
    images: &'a BTreeMap<String, game_resources::Image>,
    views: Vec<View>,
}

fn main() -> Result<()> {
    let mut args = env::args().skip(1);
    let out = PathBuf::from(
        args.next()
            .context("usage: maps <out dir> [map names...]")?,
    );
    let only: Vec<String> = args.collect();

    // map name -> .altx; later directories win
    let mut maps = BTreeMap::new();
    for dir in map_dirs() {
        println!("reading maps in {}", dir.display());
        for entry in fs::read_dir(&dir)? {
            let path = entry?.path();
            if path.extension().is_some_and(|e| e == "altx") {
                let name = path.file_stem().unwrap().to_string_lossy().into_owned();
                if let Some(previous) = maps.insert(name.clone(), path.clone()) {
                    println!(
                        "{name}: using {} instead of {}",
                        path.display(),
                        previous.display()
                    );
                }
            }
        }
    }
    let todo: Vec<_> = maps
        .iter()
        .filter(|(name, _)| only.is_empty() || only.contains(name))
        .collect();

    let version = version();
    let done: usize = todo
        .par_iter()
        .map(
            |(name, path)| match extract(path, &out.join(name), &version) {
                Ok(summary) => {
                    println!("{name}: {summary}");
                    1
                }
                Err(e) => {
                    println!("{name}: FAILED: {e:#}");
                    0
                }
            },
        )
        .sum();
    println!("extracted {done} map(s) into {}", out.display());
    Ok(())
}

fn map_dirs() -> Vec<PathBuf> {
    let mut dirs = vec![PathBuf::from("alti_home/maps")];
    if let Ok(local) = env::var("LOCALAPPDATA") {
        dirs.push(Path::new(&local).join("NimblyGames/Altitude/maps/download"));
    }
    if let Some(extra) = env::var_os("ALTI_MAP_DIRS") {
        dirs.extend(env::split_paths(&extra));
    }
    dirs.into_iter().filter(|d| d.is_dir()).collect()
}

fn extract(archive_path: &Path, out: &Path, version: &str) -> Result<String> {
    let files = read_archive(&fs::read(archive_path)?)?;
    clean_dir(out)?;

    let mut pages = Pages::default();
    let mut page_paths: Vec<_> = files.iter().filter(|(path, _)| is_page(path)).collect();
    page_paths.sort_by(|a, b| a.0.cmp(&b.0));
    for (path, data) in page_paths {
        let prefix = path[IMAGE_ROOT.len()..].replace('/', "_");
        pages
            .add(data, &prefix, out)
            .with_context(|| format!("page {path}"))?;
    }

    let (level_path, level_data) = files
        .iter()
        .find(|(path, _)| path.ends_with(".alte"))
        .context("no level (.alte) in archive")?;
    let text = String::from_utf8_lossy(level_data);
    let doc = roxmltree::Document::parse(&text)?;
    let level = doc.root_element();
    let views = children(level, "views")
        .flat_map(|vs| children(vs, "View"))
        .map(read_view)
        .collect::<Result<Vec<_>>>()?;

    let json = MapArt {
        version,
        level: Path::new(level_path)
            .file_stem()
            .unwrap()
            .to_string_lossy()
            .into_owned(),
        background: level
            .attribute("backgroundColor")
            .and_then(|c| c.parse().ok())
            .unwrap_or(0),
        pages: &pages.pages,
        images: &pages.images,
        views,
    };
    fs::write(out.join("map.json"), serde_json::to_string(&json)?)?;

    let tiles: usize = pages.pages.iter().map(|p| p.tiles.len()).sum();
    Ok(format!(
        "{} pages, {tiles} tiles, {} images",
        pages.pages.len(),
        pages.images.len()
    ))
}

fn is_page(path: &str) -> bool {
    let Some(rest) = path.strip_prefix(IMAGE_ROOT) else {
        return false;
    };
    let file = rest.rsplit('/').next().unwrap_or(rest);
    file.len() > 1 && file.starts_with('p') && file[1..].bytes().all(|b| b.is_ascii_digit())
}

fn read_view(view: roxmltree::Node) -> Result<View> {
    let size: Vec<i32> = view
        .attribute("size")
        .unwrap_or("0,0")
        .split(',')
        .map(|v| v.trim().parse().unwrap_or(0))
        .collect();
    let mut items = Vec::new();
    for geometries in children(view, "geometry") {
        for g in children(geometries, "geometry") {
            if g.attribute("visible") != Some("true") {
                continue;
            }
            let Some(poly) = children(g, "texturedPoly").next() else {
                continue;
            };
            items.push(Item {
                poly: read_textured_poly(poly)?,
                layer: g
                    .attribute("layer")
                    .and_then(|l| l.parse().ok())
                    .unwrap_or(0),
                x: attr_f64(g, "x"),
                y: attr_f64(g, "y"),
                rotation: attr_f64(g, "orientation"),
            });
        }
    }
    // stable sort, lower layers first
    items.sort_by_key(|item| item.layer);
    Ok(View {
        name: view.attribute("name").unwrap_or("").to_string(),
        w: size.first().copied().unwrap_or(0),
        h: size.get(1).copied().unwrap_or(0),
        items,
    })
}
