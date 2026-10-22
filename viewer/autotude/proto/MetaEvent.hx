package autotude.proto;
import protohx.Protohx;
class MetaEvent extends protohx.Message {

	/** LABEL_OPTIONAL data : TYPE_STRING = 1 */
	@:isVar public var data(get, set):PT_String;
	public inline function setData(value:PT_String):MetaEvent{
		this.data = value;
		return this;
	}

	public function clearData():Void {
		this.data = null;
	}

	inline public function hasData():Bool {
		return this.data != null;
	}

	public function set_data(value:PT_String):PT_String{
		return this.data = value;
	}

	public function get_data():PT_String {
		return this.data;
	}

	public function new(){
		super();
	}

	/** @private */
	override public function writeToBuffer(output:PT_OutputStream):Void {
		if (hasData()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.LENGTH_DELIMITED, 1);
			protohx.WriteUtils.write__TYPE_STRING(output, this.data);
		}
		super.writeExtensionOrUnknownFields(output);
	}

	override public function forEachFields(fn:String->Dynamic->Void):Void {
		if (hasData()) {
			fn("data", this.data);
		}
	}

	/** @private */
	override public function readFromSlice(input:PT_InputStream, bytesAfterSlice:PT_UInt):Void {
		var data__count:PT_UInt = 0;
		while (hasBytes(input, bytesAfterSlice)) {
			var tag:PT_UInt = protohx.ReadUtils.read__TYPE_UINT32(input);
			switch (tag >> 3) {
			case 1:
				if (data__count != 0) {
					throw new PT_IOError('Bad data format: MetaEvent.data cannot be set twice.');
				}
				++data__count;
				this.data = protohx.ReadUtils.read__TYPE_STRING(input);
			default:
				super.readUnknown(input, tag);
			}
		}
	}

}

