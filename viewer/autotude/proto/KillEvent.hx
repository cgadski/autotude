package autotude.proto;
import protohx.Protohx;
class KillEvent extends protohx.Message {

	/** LABEL_OPTIONAL who_killed : TYPE_UINT32 = 1 */
	@:isVar public var whoKilled(get, set):PT_UInt;
	public inline function setWhoKilled(value:PT_UInt):KillEvent{
		this.whoKilled = value;
		return this;
	}

	private var hasField__0:PT_UInt = 0;

	public function clearWhoKilled():Void {
		hasField__0 &= 0xfffffffe;
		this.whoKilled = 0;
	}

	inline public function hasWhoKilled():PT_Bool {
		return (hasField__0 & 0x1) != 0;
	}

	public function set_whoKilled(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x1;
		return this.whoKilled = value;
	}

	public function get_whoKilled():PT_UInt {
		return this.whoKilled;
	}


	/** LABEL_OPTIONAL who_died : TYPE_UINT32 = 2 */
	@:isVar public var whoDied(get, set):PT_UInt;
	public inline function setWhoDied(value:PT_UInt):KillEvent{
		this.whoDied = value;
		return this;
	}

	public function clearWhoDied():Void {
		hasField__0 &= 0xfffffffd;
		this.whoDied = 0;
	}

	inline public function hasWhoDied():PT_Bool {
		return (hasField__0 & 0x2) != 0;
	}

	public function set_whoDied(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x2;
		return this.whoDied = value;
	}

	public function get_whoDied():PT_UInt {
		return this.whoDied;
	}

	public function new(){
		super();
	}

	/** @private */
	override public function writeToBuffer(output:PT_OutputStream):Void {
		if (hasWhoKilled()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 1);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.whoKilled);
		}
		if (hasWhoDied()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 2);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.whoDied);
		}
		super.writeExtensionOrUnknownFields(output);
	}

	override public function forEachFields(fn:String->Dynamic->Void):Void {
		if (hasWhoKilled()) {
			fn("whoKilled", this.whoKilled);
		}
		if (hasWhoDied()) {
			fn("whoDied", this.whoDied);
		}
	}

	/** @private */
	override public function readFromSlice(input:PT_InputStream, bytesAfterSlice:PT_UInt):Void {
		var who_killed__count:PT_UInt = 0;
		var who_died__count:PT_UInt = 0;
		while (hasBytes(input, bytesAfterSlice)) {
			var tag:PT_UInt = protohx.ReadUtils.read__TYPE_UINT32(input);
			switch (tag >> 3) {
			case 1:
				if (who_killed__count != 0) {
					throw new PT_IOError('Bad data format: KillEvent.whoKilled cannot be set twice.');
				}
				++who_killed__count;
				this.whoKilled = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 2:
				if (who_died__count != 0) {
					throw new PT_IOError('Bad data format: KillEvent.whoDied cannot be set twice.');
				}
				++who_died__count;
				this.whoDied = protohx.ReadUtils.read__TYPE_UINT32(input);
			default:
				super.readUnknown(input, tag);
			}
		}
	}

}

