package autotude.proto;
import protohx.Protohx;
class DamageEvent extends protohx.Message {

	/** LABEL_OPTIONAL source : TYPE_UINT32 = 1 */
	@:isVar public var source(get, set):PT_UInt;
	public inline function setSource(value:PT_UInt):DamageEvent{
		this.source = value;
		return this;
	}

	private var hasField__0:PT_UInt = 0;

	public function clearSource():Void {
		hasField__0 &= 0xfffffffe;
		this.source = 0;
	}

	inline public function hasSource():PT_Bool {
		return (hasField__0 & 0x1) != 0;
	}

	public function set_source(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x1;
		return this.source = value;
	}

	public function get_source():PT_UInt {
		return this.source;
	}


	/** LABEL_OPTIONAL target : TYPE_UINT32 = 2 */
	@:isVar public var target(get, set):PT_UInt;
	public inline function setTarget(value:PT_UInt):DamageEvent{
		this.target = value;
		return this;
	}

	public function clearTarget():Void {
		hasField__0 &= 0xfffffffd;
		this.target = 0;
	}

	inline public function hasTarget():PT_Bool {
		return (hasField__0 & 0x2) != 0;
	}

	public function set_target(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x2;
		return this.target = value;
	}

	public function get_target():PT_UInt {
		return this.target;
	}


	/** LABEL_OPTIONAL amount : TYPE_UINT32 = 3 */
	@:isVar public var amount(get, set):PT_UInt;
	public inline function setAmount(value:PT_UInt):DamageEvent{
		this.amount = value;
		return this;
	}

	public function clearAmount():Void {
		hasField__0 &= 0xfffffffb;
		this.amount = 0;
	}

	inline public function hasAmount():PT_Bool {
		return (hasField__0 & 0x4) != 0;
	}

	public function set_amount(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x4;
		return this.amount = value;
	}

	public function get_amount():PT_UInt {
		return this.amount;
	}


	/** LABEL_OPTIONAL angle : TYPE_UINT32 = 4 */
	@:isVar public var angle(get, set):PT_UInt;
	public inline function setAngle(value:PT_UInt):DamageEvent{
		this.angle = value;
		return this;
	}

	public function clearAngle():Void {
		hasField__0 &= 0xfffffff7;
		this.angle = 0;
	}

	inline public function hasAngle():PT_Bool {
		return (hasField__0 & 0x8) != 0;
	}

	public function set_angle(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x8;
		return this.angle = value;
	}

	public function get_angle():PT_UInt {
		return this.angle;
	}

	public function new(){
		super();
	}

	/** @private */
	override public function writeToBuffer(output:PT_OutputStream):Void {
		if (hasSource()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 1);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.source);
		}
		if (hasTarget()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 2);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.target);
		}
		if (hasAmount()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 3);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.amount);
		}
		if (hasAngle()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 4);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.angle);
		}
		super.writeExtensionOrUnknownFields(output);
	}

	override public function forEachFields(fn:String->Dynamic->Void):Void {
		if (hasSource()) {
			fn("source", this.source);
		}
		if (hasTarget()) {
			fn("target", this.target);
		}
		if (hasAmount()) {
			fn("amount", this.amount);
		}
		if (hasAngle()) {
			fn("angle", this.angle);
		}
	}

	/** @private */
	override public function readFromSlice(input:PT_InputStream, bytesAfterSlice:PT_UInt):Void {
		var source__count:PT_UInt = 0;
		var target__count:PT_UInt = 0;
		var amount__count:PT_UInt = 0;
		var angle__count:PT_UInt = 0;
		while (hasBytes(input, bytesAfterSlice)) {
			var tag:PT_UInt = protohx.ReadUtils.read__TYPE_UINT32(input);
			switch (tag >> 3) {
			case 1:
				if (source__count != 0) {
					throw new PT_IOError('Bad data format: DamageEvent.source cannot be set twice.');
				}
				++source__count;
				this.source = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 2:
				if (target__count != 0) {
					throw new PT_IOError('Bad data format: DamageEvent.target cannot be set twice.');
				}
				++target__count;
				this.target = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 3:
				if (amount__count != 0) {
					throw new PT_IOError('Bad data format: DamageEvent.amount cannot be set twice.');
				}
				++amount__count;
				this.amount = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 4:
				if (angle__count != 0) {
					throw new PT_IOError('Bad data format: DamageEvent.angle cannot be set twice.');
				}
				++angle__count;
				this.angle = protohx.ReadUtils.read__TYPE_UINT32(input);
			default:
				super.readUnknown(input, tag);
			}
		}
	}

}

