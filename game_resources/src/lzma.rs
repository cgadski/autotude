//! Decoder for raw ".lzma" (LZMA-alone) streams, as used by Altitude's map
//! archives and texture pages. Follows the reference LzmaSpec decoder.
//!
//! Written out here rather than using a crate because callers need to know
//! exactly where a stream ends: in texture pages, a JPEG follows the alpha
//! mask's stream.

use anyhow::{bail, Result};

pub struct Decoded {
    pub data: Vec<u8>,
    /// Length of the stream in bytes, header included.
    pub consumed: usize,
}

const PROB_INIT: u16 = 1024;
const NUM_STATES: usize = 12;
const END_POS_MODEL_INDEX: u32 = 14;
const NUM_FULL_DISTANCES: usize = 128;
const MATCH_MIN_LEN: usize = 2;

struct RangeDecoder<'a> {
    src: &'a [u8],
    pos: usize,
    range: u32,
    code: u32,
}

impl<'a> RangeDecoder<'a> {
    fn next_byte(&mut self) -> Result<u8> {
        let Some(&b) = self.src.get(self.pos) else {
            bail!("lzma: unexpected end of input")
        };
        self.pos += 1;
        Ok(b)
    }

    fn normalize(&mut self) -> Result<()> {
        if self.range < 1 << 24 {
            self.range <<= 8;
            self.code = (self.code << 8) | self.next_byte()? as u32;
        }
        Ok(())
    }

    fn bit(&mut self, probs: &mut [u16], i: usize) -> Result<u32> {
        let v = probs[i] as u32;
        let bound = (self.range >> 11) * v;
        let symbol = if self.code < bound {
            probs[i] = (v + ((2048 - v) >> 5)) as u16;
            self.range = bound;
            0
        } else {
            probs[i] = (v - (v >> 5)) as u16;
            self.code -= bound;
            self.range -= bound;
            1
        };
        self.normalize()?;
        Ok(symbol)
    }

    fn direct_bits(&mut self, num_bits: u32) -> Result<u32> {
        let mut res = 0u32;
        for _ in 0..num_bits {
            self.range >>= 1;
            self.code = self.code.wrapping_sub(self.range);
            let t = 0u32.wrapping_sub(self.code >> 31);
            self.code = self.code.wrapping_add(self.range & t);
            if self.code == self.range {
                bail!("lzma: corrupted direct bits");
            }
            self.normalize()?;
            res = (res << 1).wrapping_add(t.wrapping_add(1));
        }
        Ok(res)
    }

    fn bit_tree(&mut self, probs: &mut [u16], base: usize, num_bits: u32) -> Result<u32> {
        let mut m = 1usize;
        for _ in 0..num_bits {
            m = (m << 1) + self.bit(probs, base + m)? as usize;
        }
        Ok(m as u32 - (1 << num_bits))
    }

    fn bit_tree_reverse(&mut self, probs: &mut [u16], base: usize, num_bits: u32) -> Result<u32> {
        let mut m = 1usize;
        let mut symbol = 0u32;
        for i in 0..num_bits {
            let b = self.bit(probs, base + m)?;
            m = (m << 1) + b as usize;
            symbol |= b << i;
        }
        Ok(symbol)
    }
}

struct LenDecoder {
    choice: Vec<u16>,
    low: Vec<u16>,
    mid: Vec<u16>,
    high: Vec<u16>,
}

impl LenDecoder {
    fn new() -> Self {
        LenDecoder {
            choice: vec![PROB_INIT; 2],
            low: vec![PROB_INIT; 16 << 3],
            mid: vec![PROB_INIT; 16 << 3],
            high: vec![PROB_INIT; 1 << 8],
        }
    }

    fn decode(&mut self, rc: &mut RangeDecoder, pos_state: usize) -> Result<usize> {
        if rc.bit(&mut self.choice, 0)? == 0 {
            return Ok(rc.bit_tree(&mut self.low, pos_state << 3, 3)? as usize);
        }
        if rc.bit(&mut self.choice, 1)? == 0 {
            return Ok(8 + rc.bit_tree(&mut self.mid, pos_state << 3, 3)? as usize);
        }
        Ok(16 + rc.bit_tree(&mut self.high, 0, 8)? as usize)
    }
}

/// Decode the stream at the start of `src`. Stops at the end marker or after
/// the size declared in the header.
pub fn decode(src: &[u8]) -> Result<Decoded> {
    let mut rc = RangeDecoder {
        src,
        pos: 0,
        range: 0xFFFF_FFFF,
        code: 0,
    };

    // header: properties byte, u32 dictionary size, u64 unpacked size
    let mut d = rc.next_byte()? as u32;
    if d >= 9 * 5 * 5 {
        bail!("lzma: bad properties");
    }
    let lc = d % 9;
    d /= 9;
    let lp = d % 5;
    let pb = d / 5;
    for _ in 0..4 {
        rc.next_byte()?; // dictionary size; we keep the whole output anyway
    }
    let mut size_bytes = [0u8; 8];
    for b in size_bytes.iter_mut() {
        *b = rc.next_byte()?;
    }
    let unpack_size = if size_bytes.iter().all(|&b| b == 0xFF) {
        None
    } else {
        Some(u64::from_le_bytes(size_bytes) as usize)
    };

    // range coder init
    if rc.next_byte()? != 0 {
        bail!("lzma: bad range coder header");
    }
    for _ in 0..4 {
        rc.code = (rc.code << 8) | rc.next_byte()? as u32;
    }
    if rc.code == rc.range {
        bail!("lzma: bad range coder header");
    }

    let mut out: Vec<u8> = Vec::with_capacity(unpack_size.unwrap_or(1 << 16));
    let mut literal = vec![PROB_INIT; 0x300 << (lc + lp)];
    let mut pos_slot = vec![PROB_INIT; 4 << 6];
    let mut pos_decoders = vec![PROB_INIT; 1 + NUM_FULL_DISTANCES - END_POS_MODEL_INDEX as usize];
    let mut align = vec![PROB_INIT; 1 << 4];
    let mut is_match = vec![PROB_INIT; NUM_STATES << 4];
    let mut is_rep = vec![PROB_INIT; NUM_STATES];
    let mut is_rep_g0 = vec![PROB_INIT; NUM_STATES];
    let mut is_rep_g1 = vec![PROB_INIT; NUM_STATES];
    let mut is_rep_g2 = vec![PROB_INIT; NUM_STATES];
    let mut is_rep0_long = vec![PROB_INIT; NUM_STATES << 4];
    let mut len_dec = LenDecoder::new();
    let mut rep_len_dec = LenDecoder::new();

    let mut state = 0usize;
    let (mut rep0, mut rep1, mut rep2, mut rep3) = (0u32, 0u32, 0u32, 0u32);
    let pb_mask = (1usize << pb) - 1;
    let lp_mask = (1usize << lp) - 1;

    loop {
        if unpack_size == Some(out.len()) {
            break;
        }
        let pos_state = out.len() & pb_mask;

        if rc.bit(&mut is_match, (state << 4) + pos_state)? == 0 {
            let prev_byte = out.last().copied().unwrap_or(0) as usize;
            let base = 0x300 * (((out.len() & lp_mask) << lc) + (prev_byte >> (8 - lc)));
            let mut symbol = 1usize;
            if state >= 7 {
                let mut match_byte = out[out.len() - rep0 as usize - 1] as usize;
                loop {
                    let match_bit = (match_byte >> 7) & 1;
                    match_byte <<= 1;
                    let b = rc.bit(&mut literal, base + ((1 + match_bit) << 8) + symbol)? as usize;
                    symbol = (symbol << 1) | b;
                    if match_bit != b || symbol >= 0x100 {
                        break;
                    }
                }
            }
            while symbol < 0x100 {
                symbol = (symbol << 1) | rc.bit(&mut literal, base + symbol)? as usize;
            }
            out.push((symbol - 0x100) as u8);
            state = if state < 4 {
                0
            } else if state < 10 {
                state - 3
            } else {
                state - 6
            };
            continue;
        }

        let len;
        if rc.bit(&mut is_rep, state)? != 0 {
            if out.is_empty() {
                bail!("lzma: rep match at stream start");
            }
            if rc.bit(&mut is_rep_g0, state)? == 0 {
                if rc.bit(&mut is_rep0_long, (state << 4) + pos_state)? == 0 {
                    state = if state < 7 { 9 } else { 11 };
                    let b = out[out.len() - rep0 as usize - 1];
                    out.push(b);
                    continue;
                }
            } else {
                let dist;
                if rc.bit(&mut is_rep_g1, state)? == 0 {
                    dist = rep1;
                } else {
                    if rc.bit(&mut is_rep_g2, state)? == 0 {
                        dist = rep2;
                    } else {
                        dist = rep3;
                        rep3 = rep2;
                    }
                    rep2 = rep1;
                }
                rep1 = rep0;
                rep0 = dist;
            }
            len = rep_len_dec.decode(&mut rc, pos_state)?;
            state = if state < 7 { 8 } else { 11 };
        } else {
            rep3 = rep2;
            rep2 = rep1;
            rep1 = rep0;
            len = len_dec.decode(&mut rc, pos_state)?;
            state = if state < 7 { 7 } else { 10 };

            // distance
            let len_state = len.min(3);
            let slot = rc.bit_tree(&mut pos_slot, len_state << 6, 6)?;
            if slot < 4 {
                rep0 = slot;
            } else {
                let num_direct_bits = (slot >> 1) - 1;
                let mut dist = (2 | (slot & 1)) << num_direct_bits;
                if slot < END_POS_MODEL_INDEX {
                    dist += rc.bit_tree_reverse(
                        &mut pos_decoders,
                        (dist - slot) as usize,
                        num_direct_bits,
                    )?;
                } else {
                    dist += rc.direct_bits(num_direct_bits - 4)? << 4;
                    dist += rc.bit_tree_reverse(&mut align, 0, 4)?;
                }
                rep0 = dist;
            }

            if rep0 == 0xFFFF_FFFF {
                break; // end marker
            }
            if rep0 as usize >= out.len() {
                bail!("lzma: distance out of range");
            }
        }

        let len = len + MATCH_MIN_LEN;
        if let Some(size) = unpack_size {
            if out.len() + len > size {
                bail!("lzma: match past declared size");
            }
        }
        let from = out.len() - rep0 as usize - 1;
        for k in 0..len {
            let b = out[from + k];
            out.push(b);
        }
    }

    Ok(Decoded {
        data: out,
        consumed: rc.pos,
    })
}
