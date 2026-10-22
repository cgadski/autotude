package autotude.proto;
import protohx.Protohx;
class RemovePlayerEvent extends protohx.Message {

	/** LABEL_OPTIONAL id : TYPE_UINT32 = 1 */
	@:isVar public var id(get, set):PT_UInt;
	public inline function setId(value:PT_UInt):RemovePlayerEvent{
		this.id = value;
		return this;
	}

	private var hasField__0:PT_UInt = 0;

	public function clearId():Void {
		hasField__0 &= 0xfffffffe;
		this.id = 0;
	}

	inline public function hasId():PT_Bool {
		return (hasField__0 & 0x1) != 0;
	}

	public function set_id(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x1;
		return this.id = value;
	}

	public function get_id():PT_UInt {
		return this.id;
	}

	public function new(){
		super();
	}

	/** @private */
	override public function writeToBuffer(output:PT_OutputStream):Void {
		if (hasId()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 1);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.id);
		}
		super.writeExtensionOrUnknownFields(output);
	}

	override public function forEachFields(fn:String->Dynamic->Void):Void {
		if (hasId()) {
			fn("id", this.id);
		}
	}

	/** @private */
	override public function readFromSlice(input:PT_InputStream, bytesAfterSlice:PT_UInt):Void {
		var id__count:PT_UInt = 0;
		while (hasBytes(input, bytesAfterSlice)) {
			var tag:PT_UInt = protohx.ReadUtils.read__TYPE_UINT32(input);
			switch (tag >> 3) {
			case 1:
				if (id__count != 0) {
					throw new PT_IOError('Bad data format: RemovePlayerEvent.id cannot be set twice.');
				}
				++id__count;
				this.id = protohx.ReadUtils.read__TYPE_UINT32(input);
			default:
				super.readUnknown(input, tag);
			}
		}
	}

}

