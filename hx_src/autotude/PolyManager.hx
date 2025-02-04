package autotude;

import haxe.io.BytesOutput;
import format.gz.Reader;
import haxe.ds.Map;
import autotude.proto.Poly;
import protohx.ReadingBuffer;
import haxe.io.BytesInput;

class PolyManager {
	final polyLookup:Map<Int, Poly> = new Map();
	final spinTables:Map<Int, Array<Int>> = new Map();

	inline function makeKey(type:Int, spin:Null<Int> = null):Int {
		return 5000 * type + (spin == null ? 0 : spin);
	}

	public function new(bytes:BytesInput) {
		final reader = new Reader(bytes);
		final decompressed = new BytesOutput();
		reader.readHeader();
		reader.readData(decompressed);
		final buf = new ReadingBuffer(new BytesInput(decompressed.getBytes()));

		while (buf.bytesAvailable > 0) {
			final poly = new Poly();
			poly.mergeDelimitedFrom(buf);

			polyLookup.set(makeKey(poly.type, poly.spin), poly);
			final table = spinTables.get(poly.type);
			if (table == null) {
				spinTables.set(poly.type, [poly.spin]);
			} else {
				table.push(poly.spin);
			}
		}
	}

	// normalize to the range [-180, 180)
	inline function normalizeAngleDiff(angle:Int) {
		return ((angle + 180) % 360 + 360) % 360 - 180;
	}

	public function getPoly(type:Int, spin:Null<Int> = null):Null<Poly> {
		if (spin == null) {
			return polyLookup.get(makeKey(type));
		}

		// TODO: optimize if this shows up in profiler
		// (the spins at which rendered polys are available are _not_ uniformly distributed)
		final spins = spinTables.get(type);
		if (spins == null) {
			return null;
		}

		var bestSpin = 0;
		var bestDiff = normalizeAngleDiff(spin);
		for (possibleSpin in spins) {
			final diff = normalizeAngleDiff(spin - possibleSpin);
			if (Math.abs(diff) < Math.abs(bestDiff)) {
				bestSpin = possibleSpin;
				bestDiff = diff;
			}
		}

		return polyLookup.get(makeKey(type, bestSpin));
	}
}
