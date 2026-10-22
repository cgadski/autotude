package autotude.proto;
import protohx.Protohx;
class GoalEvent extends protohx.Message {

	/** LABEL_REPEATED who_scored : TYPE_UINT32 = 2 */
	@:isVar public var whoScored(get, set):Array<PT_UInt>;
	public inline function setWhoScored(value:Array<PT_UInt>):GoalEvent{
		this.whoScored = value;
		return this;
	}

	public function set_whoScored(value:Array<PT_UInt>):Array<PT_UInt> {
		return this.whoScored = value;
	}

	public function get_whoScored():Array<PT_UInt> {
		return this.whoScored;
	}

	public function addWhoScored(value:PT_UInt):Void {
		if(this.whoScored == null) this.whoScored = [value];
		else this.whoScored.push(value);
	}

	public function new(){
		super();
		this.whoScored = [];
	}

	/** @private */
	override public function writeToBuffer(output:PT_OutputStream):Void {
		if (this.whoScored != null) {
			for (value in this.whoScored) {
				protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 2);
				protohx.WriteUtils.write__TYPE_UINT32(output, value);
			}
		}
		super.writeExtensionOrUnknownFields(output);
	}

	override public function forEachFields(fn:String->Dynamic->Void):Void {
		if (this.whoScored != null && this.whoScored.length > 0) {
			fn("whoScored", this.whoScored);
		}
	}

	/** @private */
	override public function readFromSlice(input:PT_InputStream, bytesAfterSlice:PT_UInt):Void {
		while (hasBytes(input, bytesAfterSlice)) {
			var tag:PT_UInt = protohx.ReadUtils.read__TYPE_UINT32(input);
			switch (tag >> 3) {
			case 2:
				if(this.whoScored == null) {
					this.whoScored = [];
				}
				if (cast((tag & 7), PT_UInt) == protohx.WireType.LENGTH_DELIMITED) {
					protohx.ReadUtils.readPackedRepeated(input, protohx.ReadUtils.read__TYPE_UINT32, this.whoScored);
				} else 				{
					this.whoScored.push(cast protohx.ReadUtils.read__TYPE_UINT32(input));
				}
			default:
				super.readUnknown(input, tag);
			}
		}
	}

}

