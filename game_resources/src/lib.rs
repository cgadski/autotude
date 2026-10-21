//! Shared pieces of the game resource extractors (see bin/maps.rs and
//! bin/sprites.rs).
//!
//! Texture pages (`.image/**/pN`, in map archives and in an install's
//! resources/dist) pack one or more images:
//!
//! ```text
//! u32 count, count x (u16 len, utf8 path, i32 x, i32 y, i32 w, i32 h)  (little-endian)
//! then big-endian. Map pages:
//!   i32 10002, i32 format, i32, i32, i32 tile count,
//!   tiles x (i32 w, i32 h, i32 size, size bytes: i32, LZMA alpha mask, JPEG)
//! The game's own pages are uncompressed:
//!   i32 format, i32, i32, i32 tile count, tiles x (i32 w, i32 h, w * h RGBA)
//! ```
//!
//! Pages are y-up like GL textures: tiles fill rows starting at the bottom, and
//! image rectangles are measured from the bottom-left. We flip both to the
//! top-down coordinates a canvas uses.

pub mod lzma;

use anyhow::{bail, Context, Result};
use serde::Serialize;
use std::collections::BTreeMap;
use std::fs;
use std::path::Path;

const COMPRESSED_PAGE: i32 = 10002;

#[derive(Serialize)]
pub struct Tile {
    pub x: i32,
    pub y: i32,
    pub w: i32,
    pub h: i32,
    pub file: String,
    pub alpha: Option<String>,
}

#[derive(Serialize)]
pub struct Page {
    pub w: i32,
    pub h: i32,
    pub tiles: Vec<Tile>,
}

#[derive(Serialize, Clone)]
pub struct Image {
    pub page: usize,
    pub x: i32,
    pub y: i32,
    pub w: i32,
    pub h: i32,
}

/// Pages and the images packed into them, as the viewer loads them.
#[derive(Default)]
pub struct Pages {
    pub pages: Vec<Page>,
    pub images: BTreeMap<String, Image>,
}

struct Reader<'a> {
    data: &'a [u8],
    pos: usize,
}

impl<'a> Reader<'a> {
    fn take(&mut self, n: usize) -> Result<&'a [u8]> {
        let Some(bytes) = self.data.get(self.pos..self.pos + n) else {
            bail!("unexpected end of data")
        };
        self.pos += n;
        Ok(bytes)
    }
    fn u16_le(&mut self) -> Result<u16> {
        Ok(u16::from_le_bytes(self.take(2)?.try_into()?))
    }
    fn i32_le(&mut self) -> Result<i32> {
        Ok(i32::from_le_bytes(self.take(4)?.try_into()?))
    }
    fn i32_be(&mut self) -> Result<i32> {
        Ok(i32::from_be_bytes(self.take(4)?.try_into()?))
    }
    fn string(&mut self) -> Result<String> {
        let len = self.u16_le()? as usize;
        Ok(String::from_utf8_lossy(self.take(len)?).into_owned())
    }
}

/// Files in an LZMA-compressed archive (.altx):
/// u32 count, count x (u16 len, utf8 path), count x u32 size, file data...
pub fn read_archive(compressed: &[u8]) -> Result<Vec<(String, Vec<u8>)>> {
    let data = lzma::decode(compressed)?.data;
    let mut r = Reader {
        data: &data,
        pos: 0,
    };
    let count = r.i32_le()? as usize;
    let names = (0..count).map(|_| r.string()).collect::<Result<Vec<_>>>()?;
    let sizes = (0..count).map(|_| r.i32_le()).collect::<Result<Vec<_>>>()?;
    let mut files = Vec::with_capacity(count);
    for (name, size) in names.into_iter().zip(sizes) {
        files.push((name, r.take(size as usize)?.to_vec()));
    }
    Ok(files)
}

impl Pages {
    /// Add a page, writing its tiles into `out` as `<prefix>_<i>.jpg` (with
    /// `<prefix>_<i>_a.png` for a non-opaque alpha mask) or `<prefix>_<i>.png`.
    pub fn add(&mut self, data: &[u8], prefix: &str, out: &Path) -> Result<()> {
        let page_index = self.pages.len();
        let mut r = Reader { data, pos: 0 };
        let count = r.i32_le()? as usize;
        let (mut w, mut h) = (0, 0);
        let mut entries = Vec::with_capacity(count);
        for _ in 0..count {
            let path = r.string()?;
            let img = Image {
                page: page_index,
                x: r.i32_le()?,
                y: r.i32_le()?,
                w: r.i32_le()?,
                h: r.i32_le()?,
            };
            w = w.max(img.x + img.w);
            h = h.max(img.y + img.h);
            entries.push((path, img));
        }

        let compressed = r.i32_be()? == COMPRESSED_PAGE;
        if compressed {
            r.i32_be()?; // texture format (RGBA8, DXT5, ...)
        }
        r.i32_be()?;
        r.i32_be()?;
        let tile_count = r.i32_be()?;

        let mut tiles = Vec::new();
        let (mut tx, mut ty, mut row_h) = (0, 0, 0);
        for i in 0..tile_count {
            let tw = r.i32_be()?;
            let th = r.i32_be()?;
            let name = format!("{prefix}_{i}");
            let (file, alpha) = if compressed {
                compressed_tile(&mut r, tw, th, &name, out)?
            } else {
                raw_tile(&mut r, tw, th, &name, out)?
            };

            // tiles fill the page row by row, starting from the bottom
            if tx >= w && tx > 0 {
                tx = 0;
                ty += row_h;
                row_h = 0;
            }
            tiles.push(Tile {
                x: tx,
                y: ty,
                w: tw,
                h: th,
                file,
                alpha,
            });
            tx += tw;
            row_h = row_h.max(th);
        }
        let grid_h = ty + row_h;
        if grid_h < h {
            bail!("tiles of {prefix} cover {grid_h}px, page needs {h}px");
        }

        // flip to top-down
        for t in &mut tiles {
            t.y = grid_h - t.y - t.h;
        }
        for (path, mut img) in entries {
            img.y = grid_h - img.y - img.h;
            self.images.insert(path, img);
        }
        self.pages.push(Page {
            w,
            h: grid_h,
            tiles,
        });
        Ok(())
    }
}

// i32 size, then size bytes: i32, LZMA alpha mask, JPEG
fn compressed_tile(
    r: &mut Reader,
    w: i32,
    h: i32,
    name: &str,
    out: &Path,
) -> Result<(String, Option<String>)> {
    let size = r.i32_be()? as usize;
    let start = r.pos;
    r.i32_be()?;
    let alpha = lzma::decode(&r.data[r.pos..])?;
    let jpg_start = r.pos + alpha.consumed;
    let end = start + size;
    if r.data.get(jpg_start..jpg_start + 2) != Some(&[0xFF, 0xD8]) {
        bail!("{name}: no JPEG after alpha mask");
    }
    let jpg = format!("{name}.jpg");
    fs::write(out.join(&jpg), &r.data[jpg_start..end])?;
    r.pos = end;

    if alpha.data.len() != (w * h) as usize {
        bail!(
            "{name}: alpha mask is {} bytes, expected {}",
            alpha.data.len(),
            w * h
        );
    }
    if alpha.data.iter().all(|&a| a == 0xFF) {
        return Ok((jpg, None));
    }
    let mask = format!("{name}_a.png");
    write_png(
        &out.join(&mask),
        w as u32,
        h as u32,
        png::ColorType::Grayscale,
        &alpha.data,
    )?;
    Ok((jpg, Some(mask)))
}

// w * h RGBA pixels
fn raw_tile(
    r: &mut Reader,
    w: i32,
    h: i32,
    name: &str,
    out: &Path,
) -> Result<(String, Option<String>)> {
    let pixels = r.take((w * h * 4) as usize)?;
    let file = format!("{name}.png");
    write_png(
        &out.join(&file),
        w as u32,
        h as u32,
        png::ColorType::Rgba,
        pixels,
    )?;
    Ok((file, None))
}

fn write_png(path: &Path, w: u32, h: u32, color: png::ColorType, data: &[u8]) -> Result<()> {
    let file = fs::File::create(path).with_context(|| format!("creating {}", path.display()))?;
    let mut encoder = png::Encoder::new(std::io::BufWriter::new(file), w, h);
    encoder.set_color(color);
    encoder.set_depth(png::BitDepth::Eight);
    encoder.set_compression(png::Compression::Best);
    encoder.write_header()?.write_image_data(data)?;
    Ok(())
}

/// A polygon with a texture, as used by maps and by the game's sprites:
/// `<... hull="..."><texture><image path="..."/><xform ...><translate .../>`.
/// The image is placed at translate + flip(rotate(scale * imagePos)).
#[derive(Serialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct TexturedPoly {
    pub hull: Vec<f64>,
    pub color: i32,
    pub image: Option<String>,
    pub scale: f64,
    pub texture_rotation: f64,
    #[serde(rename = "flipX")]
    pub flip_x: bool,
    #[serde(rename = "flipY")]
    pub flip_y: bool,
    pub tx: f64,
    pub ty: f64,
}

fn child<'a, 'i>(node: roxmltree::Node<'a, 'i>, name: &str) -> Option<roxmltree::Node<'a, 'i>> {
    node.children().find(|c| c.has_tag_name(name))
}

pub fn children<'a, 'i>(
    node: roxmltree::Node<'a, 'i>,
    name: &'static str,
) -> impl Iterator<Item = roxmltree::Node<'a, 'i>> {
    node.children().filter(move |c| c.has_tag_name(name))
}

pub fn attr_f64(node: roxmltree::Node, name: &str) -> f64 {
    node.attribute(name)
        .and_then(|v| v.parse().ok())
        .unwrap_or(0.0)
}

pub fn read_textured_poly(poly: roxmltree::Node) -> Result<TexturedPoly> {
    let (hull, color) = read_hull(poly.attribute("hull").unwrap_or(""));
    let texture = child(poly, "texture").context("textured poly without a texture")?;
    let image = child(texture, "image")
        .and_then(|i| i.attribute("path"))
        .map(String::from);
    let xform = child(texture, "xform").context("texture without an xform")?;
    let translate = child(xform, "translate").context("xform without a translate")?;
    Ok(TexturedPoly {
        hull,
        color,
        image,
        scale: attr_f64(xform, "scale"),
        texture_rotation: attr_f64(xform, "rotate"),
        flip_x: xform.attribute("flipX") == Some("true"),
        flip_y: xform.attribute("flipY") == Some("true"),
        tx: attr_f64(translate, "x"),
        ty: attr_f64(translate, "y"),
    })
}

/// "!color,x,y,x,y,!color,x,y,..." where !color sets the colour of the
/// following vertices. We keep the first colour, used to fill untextured
/// polygons.
pub fn read_hull(hull: &str) -> (Vec<f64>, i32) {
    let mut points = Vec::new();
    let mut color = None;
    for token in hull.split(',').filter(|t| !t.is_empty()) {
        if let Some(c) = token.strip_prefix('!') {
            if color.is_none() {
                color = c.parse().ok();
            }
        } else if let Ok(v) = token.parse() {
            points.push(v);
        }
    }
    (points, color.unwrap_or(-1))
}

/// Changes with every extraction (seconds since 1970), so the viewer won't
/// use stale cached images.
pub fn version() -> String {
    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default();
    now.as_secs().to_string()
}

/// Empty `dir`, creating it if needed.
pub fn clean_dir(dir: &Path) -> Result<()> {
    if dir.exists() {
        fs::remove_dir_all(dir).with_context(|| format!("removing {}", dir.display()))?;
    }
    fs::create_dir_all(dir)?;
    Ok(())
}
