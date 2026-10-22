package autotude.proto;
import protohx.Protohx;
class ChatEvent extends protohx.Message {

	/** LABEL_OPTIONAL sender : TYPE_UINT32 = 1 */
	@:isVar public var sender(get, set):PT_UInt;
	public inline function setSender(value:PT_UInt):ChatEvent{
		this.sender = value;
		return this;
	}

	private var hasField__0:PT_UInt = 0;

	public function clearSender():Void {
		hasField__0 &= 0xfffffffe;
		this.sender = 0;
	}

	inline public function hasSender():PT_Bool {
		return (hasField__0 & 0x1) != 0;
	}

	public function set_sender(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x1;
		return this.sender = value;
	}

	public function get_sender():PT_UInt {
		return this.sender;
	}


	/** LABEL_OPTIONAL message : TYPE_STRING = 2 */
	@:isVar public var message(get, set):PT_String;
	public inline function setMessage(value:PT_String):ChatEvent{
		this.message = value;
		return this;
	}

	public function clearMessage():Void {
		this.message = null;
	}

	inline public function hasMessage():Bool {
		return this.message != null;
	}

	public function set_message(value:PT_String):PT_String{
		return this.message = value;
	}

	public function get_message():PT_String {
		return this.message;
	}

	public function new(){
		super();
	}

	/** @private */
	override public function writeToBuffer(output:PT_OutputStream):Void {
		if (hasSender()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 1);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.sender);
		}
		if (hasMessage()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.LENGTH_DELIMITED, 2);
			protohx.WriteUtils.write__TYPE_STRING(output, this.message);
		}
		super.writeExtensionOrUnknownFields(output);
	}

	override public function forEachFields(fn:String->Dynamic->Void):Void {
		if (hasSender()) {
			fn("sender", this.sender);
		}
		if (hasMessage()) {
			fn("message", this.message);
		}
	}

	/** @private */
	override public function readFromSlice(input:PT_InputStream, bytesAfterSlice:PT_UInt):Void {
		var sender__count:PT_UInt = 0;
		var message__count:PT_UInt = 0;
		while (hasBytes(input, bytesAfterSlice)) {
			var tag:PT_UInt = protohx.ReadUtils.read__TYPE_UINT32(input);
			switch (tag >> 3) {
			case 1:
				if (sender__count != 0) {
					throw new PT_IOError('Bad data format: ChatEvent.sender cannot be set twice.');
				}
				++sender__count;
				this.sender = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 2:
				if (message__count != 0) {
					throw new PT_IOError('Bad data format: ChatEvent.message cannot be set twice.');
				}
				++message__count;
				this.message = protohx.ReadUtils.read__TYPE_STRING(input);
			default:
				super.readUnknown(input, tag);
			}
		}
	}

}

