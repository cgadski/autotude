//! Extracts the game's sprites, effect images and sounds from an Altitude
//! install for the replay viewer.
//!
//! Run with --help for usage.
//!
//! Writes `<out>/sprites/` (texture page tiles and sprites.json) and
//! `<out>/sounds/` (the game's .ogg sounds, not music). The polys the game
//! draws for objects (TYPES below) are textured polys in its dist/.poly; we
//! take each one's frames and every texture page in the directories of the
//! images they use from dist/.image. Team-coloured images are named by colour
//! (e.g. 0_128_5_0070.png) and the pages hold every colour, so the viewer can
//! swap in a team's colour by name. Animated poly frames are keyed by roll
//! ("delayMs", in tenths of a degree).

use anyhow::{bail, Context, Result};
use clap::Parser;
use game_resources::{
    children, clean_dir, read_textured_poly, version, Image, Page, Pages, TexturedPoly,
};
use serde::Serialize;
use std::collections::BTreeMap;
use std::fs;
use std::path::{Path, PathBuf};

/// Object type (ObjectType in proto/game_object.proto) -> the poly the game
/// draws for it, under dist/.poly.
const TYPES: &[(i32, &str)] = &[
    // planes
    (0, "render/planes/loopy/0_128_5.animatedpoly"),
    (1, "render/planes/bomber/0_128_5.animatedpoly"),
    (2, "render/planes/explodet/0_128_5.animatedpoly"),
    (3, "render/planes/biplane/0_128_5.animatedpoly"),
    (4, "render/planes/miranda/0_128_5.animatedpoly"),
    // powerups
    (10, "planes/powerup/container.poly"), // MISSLE_POWERUP
    (11, "planes/powerup/container.poly"), // SHIELD_POWERUP
    (12, "planes/powerup/container.poly"), // WALL_POWERUP
    (13, "planes/powerup/container.poly"), // BIG_BOMB_POWERUP
    (14, "planes/powerup/ball.poly"),      // BALL
    (15, "planes/powerup/container.poly"), // HEALTH_POWERUP
    (16, "planes/powerup/container.poly"), // POWERUP_SPAWNER
    // loopy
    (20, "planes/loopy/trackingbullet.poly"), // DOUBLE_FIRE_MISSLE
    (21, "planes/loopy/trackingbullet.poly"), // TRACKER_MISSLE
    (22, "planes/loopy/emp_grenade.poly"),    // EMP_CAPSULE
    (24, "planes/loopy/acid_grenade.poly"),   // ACID_BOMB
    // bomber
    (30, "planes/bomber/grenade.poly"),                     // NADE
    (31, "planes/bomber/big_shell.poly"),                   // FLAK
    (32, "planes/bomber/gun.poly"),                         // SUPPRESSOR
    (33, "render/planes/bomber/bomb/0_128_5.animatedpoly"), // DOMB
    // biplane
    (40, "planes/biplane/bullet.poly"),        // BIPLANE_PRIMARY
    (41, "planes/biplane/bullet.poly"),        // BIPLANE_SECONDARY
    (42, "planes/biplane/bullet_cannon.poly"), // HEAVY_CANNON
    // explodet
    (50, "planes/explodet/rocket.poly"), // DIRECTOR_ROCKET
    (51, "planes/explodet/rocket.poly"), // THERMOBARIC_ROCKET
    (52, "planes/explodet/mine.poly"),   // REMOTE_MINE
    (53, "planes/explodet/mine.poly"),   // DIRECTOR_MINE
    // miranda
    (60, "planes/miranda/laser.poly"),       // LASER
    (61, "planes/miranda/charge_shot.poly"), // TRICKSTER_SHOT
    (62, "planes/miranda/charge_shot.poly"), // LASER_SHOT
    // special
    (70, "render/powerups/missile/0_128_5.animatedpoly"), // HOMING_MISSLE
    (71, "planes/powerup/wall.poly"),                     // WALL
    (72, "planes/powerup/shield/shield.poly"),            // SHIELD
    (73, "render/powerups/big_bomb/0_128_5.animatedpoly"), // BIG_BOMB
    (74, "map/goal/goal.poly"),                           // GOAL
    (75, "map/base/base.poly"),                           // BASE
];

/// Polys the viewer draws besides the ones above.
const EXTRA_POLYS: &[&str] = &[
    "effects/invuln/invuln.animatedpoly",
    "planes/powerup/health/healthpack.animatedpoly",
    "render/powerups/missile/0_128_5.animatedpoly",
    "render/powerups/big_bomb/0_128_5.animatedpoly",
    "planes/powerup/container_health.poly",
    "render/planes/explodet/mine/0_128_5.animatedpoly",
    "render/planes/explodet/drone/0_128_5.animatedpoly",
    "render/planes/explodet/rocket_open/0_128_5.animatedpoly",
    "render/planes/explodet/rocket_spin/0_128_5.animatedpoly",
];

/// Image directories the viewer uses without a poly.
const EXTRA_IMAGE_DIRS: &[&str] = &[
    "hud/over_plane", // powerup_container.png, the badge for a held powerup
    "effects",        // muzzle flashes, smoke
    "effects/afterburner",
    "effects/explosion",
    "effects/explosion_blue",
    "effects/spark",
    "effects/spawn",
    "effects/veteran_bars",
    "planes/powerup/wall",  // beam_texture.png, electric_N.png: deployed walls
    "render/powerups/wall", // team-coloured end caps of deployed walls
];

/// Sound directories (under dist/.sound/sounds) copied for the viewer: game
/// sounds, not music or menus.
const SOUND_DIRS: &[&str] = &["planes", "powerup", "map"];

#[derive(Serialize)]
struct Frame {
    #[serde(flatten)]
    poly: TexturedPoly,
    spin: i32,
}

#[derive(Serialize)]
struct Sprites<'a> {
    version: String,
    pages: &'a [Page],
    images: &'a BTreeMap<String, Image>,
    polys: BTreeMap<&'a str, Vec<Frame>>,
    types: BTreeMap<String, &'a str>,
}

/// Extract the game's sprites, effect images and sounds from an Altitude
/// install into <OUT>/sprites and <OUT>/sounds.
#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Output directory.
    out: PathBuf,

    /// Path to the Altitude install.
    #[arg(long, env = "ALTI_INSTALL")]
    install: PathBuf,
}

fn main() -> Result<()> {
    let args = Args::parse();
    let dist = find_dist(&args.install)?;
    let out = args.out;

    let mut poly_paths: Vec<&str> = EXTRA_POLYS.to_vec();
    for &(_, path) in TYPES {
        if !poly_paths.contains(&path) {
            poly_paths.push(path);
        }
    }

    let mut polys = BTreeMap::new();
    let mut image_dirs: Vec<String> = EXTRA_IMAGE_DIRS.iter().map(|d| d.to_string()).collect();
    for &path in &poly_paths {
        let frames =
            read_poly(&dist.join(".poly").join(path)).with_context(|| format!("poly {path}"))?;
        for frame in &frames {
            if let Some(dir) = frame
                .poly
                .image
                .as_deref()
                .and_then(|i| i.rsplit_once('/'))
                .map(|(d, _)| d.to_string())
            {
                if !image_dirs.contains(&dir) {
                    image_dirs.push(dir);
                }
            }
        }
        polys.insert(path, frames);
    }

    let sprites_out = out.join("sprites");
    clean_dir(&sprites_out)?;
    let mut pages = Pages::default();
    image_dirs.sort();
    for dir in &image_dirs {
        let full = dist.join(".image").join(dir);
        let mut names: Vec<String> = fs::read_dir(&full)
            .with_context(|| format!("reading {}", full.display()))?
            .filter_map(|e| e.ok().map(|e| e.file_name().to_string_lossy().into_owned()))
            .filter(|n| {
                n.len() > 1 && n.starts_with('p') && n[1..].bytes().all(|b| b.is_ascii_digit())
            })
            .collect();
        names.sort();
        for name in names {
            let prefix = format!("{}_{name}", dir.replace('/', "_"));
            pages
                .add(&fs::read(full.join(&name))?, &prefix, &sprites_out)
                .with_context(|| format!("page {dir}/{name}"))?;
        }
    }

    let json = Sprites {
        version: version(),
        pages: &pages.pages,
        images: &pages.images,
        polys,
        types: TYPES.iter().map(|&(t, p)| (t.to_string(), p)).collect(),
    };
    fs::write(
        sprites_out.join("sprites.json"),
        serde_json::to_string(&json)?,
    )?;
    println!(
        "{} polys, {} image dirs, {} pages, {} images",
        poly_paths.len(),
        image_dirs.len(),
        pages.pages.len(),
        pages.images.len()
    );

    // sounds are plain .ogg files; keep their paths (e.g. sounds/planes/plane_explode.ogg)
    let sounds_out = out.join("sounds");
    clean_dir(&sounds_out)?;
    let mut sounds = 0;
    for dir in SOUND_DIRS {
        sounds += copy_dir(&dist.join(".sound/sounds").join(dir), &sounds_out.join(dir))?;
    }
    println!("{sounds} sounds");
    Ok(())
}

fn find_dist(install: &Path) -> Result<PathBuf> {
    for sub in ["app/resources/dist", "resources/dist", ""] {
        let dir = install.join(sub);
        if dir.join(".image").is_dir() && dir.join(".poly").is_dir() {
            return Ok(dir);
        }
    }
    bail!("no resources/dist/.image in {}", install.display())
}

/// Frames of a .poly (one frame, roll 0) or .animatedpoly.
fn read_poly(path: &Path) -> Result<Vec<Frame>> {
    let text = fs::read_to_string(path)?;
    let doc = roxmltree::Document::parse(&text)?;
    let root = doc.root_element();
    if !root.has_tag_name("AnimatedPoly") {
        return Ok(vec![Frame {
            poly: read_textured_poly(root)?,
            spin: 0,
        }]);
    }
    children(root, "frames")
        .flat_map(|frames| children(frames, "Frame"))
        .map(|frame| {
            let poly = children(frame, "poly")
                .next()
                .context("frame without a poly")?;
            let delay: i32 = frame
                .attribute("delayMs")
                .and_then(|d| d.parse().ok())
                .unwrap_or(0);
            Ok(Frame {
                poly: read_textured_poly(poly)?,
                spin: delay / 10,
            })
        })
        .collect()
}

fn copy_dir(from: &Path, to: &Path) -> Result<usize> {
    fs::create_dir_all(to)?;
    let mut n = 0;
    for entry in fs::read_dir(from).with_context(|| format!("reading {}", from.display()))? {
        let entry = entry?;
        let path = entry.path();
        if path.is_dir() {
            n += copy_dir(&path, &to.join(entry.file_name()))?;
        } else {
            fs::copy(&path, to.join(entry.file_name()))?;
            n += 1;
        }
    }
    Ok(n)
}
