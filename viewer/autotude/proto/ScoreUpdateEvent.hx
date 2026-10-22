package autotude.proto;
import protohx.Protohx;
class ScoreUpdateEvent extends protohx.Message {

	/** LABEL_OPTIONAL team : TYPE_UINT32 = 1 */
	@:isVar public var team(get, set):PT_UInt;
	public inline function setTeam(value:PT_UInt):ScoreUpdateEvent{
		this.team = value;
		return this;
	}

	private var hasField__0:PT_UInt = 0;

	public function clearTeam():Void {
		hasField__0 &= 0xfffffffe;
		this.team = 0;
	}

	inline public function hasTeam():PT_Bool {
		return (hasField__0 & 0x1) != 0;
	}

	public function set_team(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x1;
		return this.team = value;
	}

	public function get_team():PT_UInt {
		return this.team;
	}


	/** LABEL_OPTIONAL points : TYPE_UINT32 = 2 */
	@:isVar public var points(get, set):PT_UInt;
	public inline function setPoints(value:PT_UInt):ScoreUpdateEvent{
		this.points = value;
		return this;
	}

	public function clearPoints():Void {
		hasField__0 &= 0xfffffffd;
		this.points = 0;
	}

	inline public function hasPoints():PT_Bool {
		return (hasField__0 & 0x2) != 0;
	}

	public function set_points(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x2;
		return this.points = value;
	}

	public function get_points():PT_UInt {
		return this.points;
	}

	public function new(){
		super();
	}

	/** @private */
	override public function writeToBuffer(output:PT_OutputStream):Void {
		if (hasTeam()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 1);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.team);
		}
		if (hasPoints()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 2);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.points);
		}
		super.writeExtensionOrUnknownFields(output);
	}

	override public function forEachFields(fn:String->Dynamic->Void):Void {
		if (hasTeam()) {
			fn("team", this.team);
		}
		if (hasPoints()) {
			fn("points", this.points);
		}
	}

	/** @private */
	override public function readFromSlice(input:PT_InputStream, bytesAfterSlice:PT_UInt):Void {
		var team__count:PT_UInt = 0;
		var points__count:PT_UInt = 0;
		while (hasBytes(input, bytesAfterSlice)) {
			var tag:PT_UInt = protohx.ReadUtils.read__TYPE_UINT32(input);
			switch (tag >> 3) {
			case 1:
				if (team__count != 0) {
					throw new PT_IOError('Bad data format: ScoreUpdateEvent.team cannot be set twice.');
				}
				++team__count;
				this.team = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 2:
				if (points__count != 0) {
					throw new PT_IOError('Bad data format: ScoreUpdateEvent.points cannot be set twice.');
				}
				++points__count;
				this.points = protohx.ReadUtils.read__TYPE_UINT32(input);
			default:
				super.readUnknown(input, tag);
			}
		}
	}

}

