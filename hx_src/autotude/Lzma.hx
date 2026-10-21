package autotude;

import haxe.ds.Vector;
import haxe.io.Bytes;

// Decoder for raw ".lzma" (LZMA-alone) streams, as used by Altitude's map
// archives and texture pages. Ported from the reference LzmaSpec decoder.
//
// Relies on 32-bit wrapping Int arithmetic, so it needs a target with real
// 32-bit ints (eval/--interp, js, hl); it will not work on neko.
class Lzma {
	static inline final PROB_INIT = 1024;
	static inline final NUM_STATES = 12;
	static inline final POS_STATES_MAX = 16;
	static inline final END_POS_MODEL_INDEX = 14;
	static inline final NUM_FULL_DISTANCES = 128;
	static inline final MATCH_MIN_LEN = 2;

	final src:Bytes;
	var inPos:Int;

	var range:Int = -1; // 0xFFFFFFFF
	var code:Int = 0;

	var out:Bytes;
	var outPos:Int = 0;

	function new(src:Bytes, pos:Int) {
		this.src = src;
		this.inPos = pos;
		this.out = Bytes.alloc(0);
	}

	/**
		Decode the stream starting at `src[pos]`. Stops at the end marker or
		after the declared size. `consumed` is the stream's length in bytes,
		since other data may follow it (e.g. a JPEG).
	**/
	public static function decode(src:Bytes, pos:Int = 0):{data:Bytes, consumed:Int} {
		final d = new Lzma(src, pos);
		final data = d.run();
		return {data: data, consumed: d.inPos - pos};
	}

	// unsigned comparison a < b
	static inline function ult(a:Int, b:Int):Bool
		return (a ^ 0x80000000) < (b ^ 0x80000000);

	inline function nextByte():Int {
		if (inPos >= src.length)
			throw "lzma: unexpected end of input";
		return src.get(inPos++);
	}

	inline function normalize() {
		if (ult(range, 1 << 24)) {
			range = range << 8;
			code = (code << 8) | nextByte();
		}
	}

	function bit(probs:Vector<Int>, i:Int):Int {
		var v = probs[i];
		final bound = (range >>> 11) * v;
		var symbol:Int;
		if (ult(code, bound)) {
			v += ((1 << 11) - v) >>> 5;
			range = bound;
			symbol = 0;
		} else {
			v -= v >>> 5;
			code -= bound;
			range -= bound;
			symbol = 1;
		}
		probs[i] = v;
		normalize();
		return symbol;
	}

	function directBits(numBits:Int):Int {
		var res = 0;
		for (_ in 0...numBits) {
			range = range >>> 1;
			code -= range;
			final t = 0 - (code >>> 31);
			code += range & t;
			if (code == range)
				throw "lzma: corrupted direct bits";
			normalize();
			res = (res << 1) + (t + 1);
		}
		return res;
	}

	function bitTree(probs:Vector<Int>, base:Int, numBits:Int):Int {
		var m = 1;
		for (_ in 0...numBits)
			m = (m << 1) + bit(probs, base + m);
		return m - (1 << numBits);
	}

	function bitTreeReverse(probs:Vector<Int>, base:Int, numBits:Int):Int {
		var m = 1;
		var symbol = 0;
		for (i in 0...numBits) {
			final b = bit(probs, base + m);
			m = (m << 1) + b;
			symbol |= b << i;
		}
		return symbol;
	}

	function ensure(extra:Int) {
		if (outPos + extra <= out.length)
			return;
		var size = out.length < 1 << 16 ? 1 << 16 : out.length;
		while (size < outPos + extra)
			size *= 2;
		final next = Bytes.alloc(size);
		next.blit(0, out, 0, outPos);
		out = next;
	}

	static function newProbs(n:Int):Vector<Int> {
		final v = new Vector<Int>(n);
		for (i in 0...n)
			v[i] = PROB_INIT;
		return v;
	}

	function run():Bytes {
		// header: properties byte, u32 dictionary size, u64 unpacked size
		var d = nextByte();
		if (d >= 9 * 5 * 5)
			throw "lzma: bad properties";
		final lc = d % 9;
		d = Std.int(d / 9);
		final lp = d % 5;
		final pb = Std.int(d / 5);
		for (_ in 0...4)
			nextByte(); // dictionary size; we keep the whole output anyway

		var sizeKnown = false;
		var unpackSize = 0;
		var hiBytes = 0;
		for (i in 0...8) {
			final b = nextByte();
			if (b != 0xFF)
				sizeKnown = true;
			if (i < 4)
				unpackSize |= b << (8 * i);
			else
				hiBytes |= b;
		}
		if (sizeKnown) {
			if (hiBytes != 0 || unpackSize < 0)
				throw "lzma: stream too large";
			out = Bytes.alloc(unpackSize);
		}

		// range coder init
		if (nextByte() != 0)
			throw "lzma: bad range coder header";
		for (_ in 0...4)
			code = (code << 8) | nextByte();
		if (code == range)
			throw "lzma: bad range coder header";

		final literal = newProbs(0x300 << (lc + lp));
		final posSlot = newProbs(4 << 6);
		final posDecoders = newProbs(1 + NUM_FULL_DISTANCES - END_POS_MODEL_INDEX);
		final align = newProbs(1 << 4);
		final isMatch = newProbs(NUM_STATES << 4);
		final isRep = newProbs(NUM_STATES);
		final isRepG0 = newProbs(NUM_STATES);
		final isRepG1 = newProbs(NUM_STATES);
		final isRepG2 = newProbs(NUM_STATES);
		final isRep0Long = newProbs(NUM_STATES << 4);
		final lenDec = new LenDecoder(this);
		final repLenDec = new LenDecoder(this);

		var state = 0;
		var rep0 = 0, rep1 = 0, rep2 = 0, rep3 = 0;
		final pbMask = (1 << pb) - 1;
		final lpMask = (1 << lp) - 1;

		while (true) {
			if (sizeKnown && outPos == unpackSize)
				break;

			final posState = outPos & pbMask;

			if (bit(isMatch, (state << 4) + posState) == 0) {
				final prevByte = outPos > 0 ? out.get(outPos - 1) : 0;
				final base = 0x300 * (((outPos & lpMask) << lc) + (prevByte >>> (8 - lc)));
				var symbol = 1;
				if (state >= 7) {
					var matchByte = out.get(outPos - rep0 - 1);
					do {
						final matchBit = (matchByte >>> 7) & 1;
						matchByte <<= 1;
						final b = bit(literal, base + ((1 + matchBit) << 8) + symbol);
						symbol = (symbol << 1) | b;
						if (matchBit != b)
							break;
					} while (symbol < 0x100);
				}
				while (symbol < 0x100)
					symbol = (symbol << 1) | bit(literal, base + symbol);
				ensure(1);
				out.set(outPos++, symbol - 0x100);
				state = state < 4 ? 0 : (state < 10 ? state - 3 : state - 6);
				continue;
			}

			var len:Int;
			if (bit(isRep, state) != 0) {
				if (outPos == 0)
					throw "lzma: rep match at stream start";
				if (bit(isRepG0, state) == 0) {
					if (bit(isRep0Long, (state << 4) + posState) == 0) {
						state = state < 7 ? 9 : 11;
						ensure(1);
						out.set(outPos, out.get(outPos - rep0 - 1));
						outPos++;
						continue;
					}
				} else {
					var dist:Int;
					if (bit(isRepG1, state) == 0) {
						dist = rep1;
					} else {
						if (bit(isRepG2, state) == 0) {
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
				len = repLenDec.decode(posState);
				state = state < 7 ? 8 : 11;
			} else {
				rep3 = rep2;
				rep2 = rep1;
				rep1 = rep0;
				len = lenDec.decode(posState);
				state = state < 7 ? 7 : 10;

				// distance
				final lenState = len < 3 ? len : 3;
				final slot = bitTree(posSlot, lenState << 6, 6);
				if (slot < 4) {
					rep0 = slot;
				} else {
					final numDirectBits = (slot >>> 1) - 1;
					var dist = (2 | (slot & 1)) << numDirectBits;
					if (slot < END_POS_MODEL_INDEX) {
						dist += bitTreeReverse(posDecoders, dist - slot, numDirectBits);
					} else {
						dist += directBits(numDirectBits - 4) << 4;
						dist += bitTreeReverse(align, 0, 4);
					}
					rep0 = dist;
				}

				if (rep0 == -1) // end marker
					break;
				if (!ult(rep0, outPos))
					throw "lzma: distance out of range";
			}

			len += MATCH_MIN_LEN;
			if (sizeKnown && outPos + len > unpackSize)
				throw "lzma: match past declared size";
			ensure(len);
			var from = outPos - rep0 - 1;
			for (_ in 0...len)
				out.set(outPos++, out.get(from++));
		}

		return out.sub(0, outPos);
	}
}

@:access(autotude.Lzma)
private class LenDecoder {
	final d:Lzma;
	final choice = Lzma.newProbs(2);
	final low = Lzma.newProbs(16 << 3);
	final mid = Lzma.newProbs(16 << 3);
	final high = Lzma.newProbs(1 << 8);

	public function new(d:Lzma) {
		this.d = d;
	}

	public function decode(posState:Int):Int {
		if (d.bit(choice, 0) == 0)
			return d.bitTree(low, posState << 3, 3);
		if (d.bit(choice, 1) == 0)
			return 8 + d.bitTree(mid, posState << 3, 3);
		return 16 + d.bitTree(high, 0, 8);
	}
}
