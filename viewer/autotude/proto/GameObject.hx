package autotude.proto;
import protohx.Protohx;
class GameObject extends protohx.Message {

	/** LABEL_OPTIONAL uid : TYPE_UINT32 = 1 */
	@:isVar public var uid(get, set):PT_UInt;
	public inline function setUid(value:PT_UInt):GameObject{
		this.uid = value;
		return this;
	}

	private var hasField__0:PT_UInt = 0;

	public function clearUid():Void {
		hasField__0 &= 0xfffffffe;
		this.uid = 0;
	}

	inline public function hasUid():PT_Bool {
		return (hasField__0 & 0x1) != 0;
	}

	public function set_uid(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x1;
		return this.uid = value;
	}

	public function get_uid():PT_UInt {
		return this.uid;
	}


	/** LABEL_OPTIONAL type : TYPE_ENUM = 2 */
	@:isVar public var type(get, set):PT_Int;
	public inline function setType(value:PT_Int):GameObject{
		this.type = value;
		return this;
	}

	public function clearType():Void {
		hasField__0 &= 0xfffffffd;
		this.type = 0;
	}

	inline public function hasType():PT_Bool {
		return (hasField__0 & 0x2) != 0;
	}

	public function set_type(value:PT_Int):PT_Int{
		hasField__0 |= 0x2;
		return this.type = value;
	}

	public function get_type():PT_Int {
		return this.type;
	}


	/** LABEL_OPTIONAL owner : TYPE_UINT32 = 3 */
	@:isVar public var owner(get, set):PT_UInt;
	public inline function setOwner(value:PT_UInt):GameObject{
		this.owner = value;
		return this;
	}

	public function clearOwner():Void {
		hasField__0 &= 0xfffffffb;
		this.owner = 0;
	}

	inline public function hasOwner():PT_Bool {
		return (hasField__0 & 0x4) != 0;
	}

	public function set_owner(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x4;
		return this.owner = value;
	}

	public function get_owner():PT_UInt {
		return this.owner;
	}


	/** LABEL_OPTIONAL team : TYPE_UINT32 = 4 */
	@:isVar public var team(get, set):PT_UInt;
	public inline function setTeam(value:PT_UInt):GameObject{
		this.team = value;
		return this;
	}

	public function clearTeam():Void {
		hasField__0 &= 0xfffffff7;
		this.team = 0;
	}

	inline public function hasTeam():PT_Bool {
		return (hasField__0 & 0x8) != 0;
	}

	public function set_team(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x8;
		return this.team = value;
	}

	public function get_team():PT_UInt {
		return this.team;
	}


	/** LABEL_OPTIONAL position_x : TYPE_UINT32 = 10 */
	@:isVar public var positionX(get, set):PT_UInt;
	public inline function setPositionX(value:PT_UInt):GameObject{
		this.positionX = value;
		return this;
	}

	public function clearPositionX():Void {
		hasField__0 &= 0xffffffef;
		this.positionX = 0;
	}

	inline public function hasPositionX():PT_Bool {
		return (hasField__0 & 0x10) != 0;
	}

	public function set_positionX(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x10;
		return this.positionX = value;
	}

	public function get_positionX():PT_UInt {
		return this.positionX;
	}


	/** LABEL_OPTIONAL position_y : TYPE_UINT32 = 11 */
	@:isVar public var positionY(get, set):PT_UInt;
	public inline function setPositionY(value:PT_UInt):GameObject{
		this.positionY = value;
		return this;
	}

	public function clearPositionY():Void {
		hasField__0 &= 0xffffffdf;
		this.positionY = 0;
	}

	inline public function hasPositionY():PT_Bool {
		return (hasField__0 & 0x20) != 0;
	}

	public function set_positionY(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x20;
		return this.positionY = value;
	}

	public function get_positionY():PT_UInt {
		return this.positionY;
	}


	/** LABEL_OPTIONAL angle : TYPE_UINT32 = 12 */
	@:isVar public var angle(get, set):PT_UInt;
	public inline function setAngle(value:PT_UInt):GameObject{
		this.angle = value;
		return this;
	}

	public function clearAngle():Void {
		hasField__0 &= 0xffffffbf;
		this.angle = 0;
	}

	inline public function hasAngle():PT_Bool {
		return (hasField__0 & 0x40) != 0;
	}

	public function set_angle(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x40;
		return this.angle = value;
	}

	public function get_angle():PT_UInt {
		return this.angle;
	}


	/** LABEL_OPTIONAL scale : TYPE_UINT32 = 20 */
	@:isVar public var scale(get, set):PT_UInt;
	public inline function setScale(value:PT_UInt):GameObject{
		this.scale = value;
		return this;
	}

	public function clearScale():Void {
		hasField__0 &= 0xffffff7f;
		this.scale = 0;
	}

	inline public function hasScale():PT_Bool {
		return (hasField__0 & 0x80) != 0;
	}

	public function set_scale(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x80;
		return this.scale = value;
	}

	public function get_scale():PT_UInt {
		return this.scale;
	}


	/** LABEL_OPTIONAL flipX : TYPE_BOOL = 21 */
	@:isVar public var flipX(get, set):PT_Bool;
	public inline function setFlipX(value:PT_Bool):GameObject{
		this.flipX = value;
		return this;
	}

	public function clearFlipX():Void {
		hasField__0 &= 0xfffffeff;
		this.flipX = false;
	}

	inline public function hasFlipX():PT_Bool {
		return (hasField__0 & 0x100) != 0;
	}

	public function set_flipX(value:PT_Bool):PT_Bool{
		hasField__0 |= 0x100;
		return this.flipX = value;
	}

	public function get_flipX():PT_Bool {
		return this.flipX;
	}


	/** LABEL_OPTIONAL flipY : TYPE_BOOL = 22 */
	@:isVar public var flipY(get, set):PT_Bool;
	public inline function setFlipY(value:PT_Bool):GameObject{
		this.flipY = value;
		return this;
	}

	public function clearFlipY():Void {
		hasField__0 &= 0xfffffdff;
		this.flipY = false;
	}

	inline public function hasFlipY():PT_Bool {
		return (hasField__0 & 0x200) != 0;
	}

	public function set_flipY(value:PT_Bool):PT_Bool{
		hasField__0 |= 0x200;
		return this.flipY = value;
	}

	public function get_flipY():PT_Bool {
		return this.flipY;
	}


	/** LABEL_OPTIONAL charge : TYPE_UINT32 = 30 */
	@:isVar public var charge(get, set):PT_UInt;
	public inline function setCharge(value:PT_UInt):GameObject{
		this.charge = value;
		return this;
	}

	public function clearCharge():Void {
		hasField__0 &= 0xfffffbff;
		this.charge = 0;
	}

	inline public function hasCharge():PT_Bool {
		return (hasField__0 & 0x400) != 0;
	}

	public function set_charge(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x400;
		return this.charge = value;
	}

	public function get_charge():PT_UInt {
		return this.charge;
	}


	/** LABEL_OPTIONAL heal_percentage : TYPE_UINT32 = 31 */
	@:isVar public var healPercentage(get, set):PT_UInt;
	public inline function setHealPercentage(value:PT_UInt):GameObject{
		this.healPercentage = value;
		return this;
	}

	public function clearHealPercentage():Void {
		hasField__0 &= 0xfffff7ff;
		this.healPercentage = 0;
	}

	inline public function hasHealPercentage():PT_Bool {
		return (hasField__0 & 0x800) != 0;
	}

	public function set_healPercentage(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x800;
		return this.healPercentage = value;
	}

	public function get_healPercentage():PT_UInt {
		return this.healPercentage;
	}


	/** LABEL_OPTIONAL time_remaining : TYPE_UINT32 = 32 */
	@:isVar public var timeRemaining(get, set):PT_UInt;
	public inline function setTimeRemaining(value:PT_UInt):GameObject{
		this.timeRemaining = value;
		return this;
	}

	public function clearTimeRemaining():Void {
		hasField__0 &= 0xffffefff;
		this.timeRemaining = 0;
	}

	inline public function hasTimeRemaining():PT_Bool {
		return (hasField__0 & 0x1000) != 0;
	}

	public function set_timeRemaining(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x1000;
		return this.timeRemaining = value;
	}

	public function get_timeRemaining():PT_UInt {
		return this.timeRemaining;
	}


	/** LABEL_OPTIONAL ammo : TYPE_UINT32 = 40 */
	@:isVar public var ammo(get, set):PT_UInt;
	public inline function setAmmo(value:PT_UInt):GameObject{
		this.ammo = value;
		return this;
	}

	public function clearAmmo():Void {
		hasField__0 &= 0xffffdfff;
		this.ammo = 0;
	}

	inline public function hasAmmo():PT_Bool {
		return (hasField__0 & 0x2000) != 0;
	}

	public function set_ammo(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x2000;
		return this.ammo = value;
	}

	public function get_ammo():PT_UInt {
		return this.ammo;
	}


	/** LABEL_OPTIONAL health : TYPE_UINT32 = 41 */
	@:isVar public var health(get, set):PT_UInt;
	public inline function setHealth(value:PT_UInt):GameObject{
		this.health = value;
		return this;
	}

	public function clearHealth():Void {
		hasField__0 &= 0xffffbfff;
		this.health = 0;
	}

	inline public function hasHealth():PT_Bool {
		return (hasField__0 & 0x4000) != 0;
	}

	public function set_health(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x4000;
		return this.health = value;
	}

	public function get_health():PT_UInt {
		return this.health;
	}


	/** LABEL_OPTIONAL health_restore : TYPE_UINT32 = 53 */
	@:isVar public var healthRestore(get, set):PT_UInt;
	public inline function setHealthRestore(value:PT_UInt):GameObject{
		this.healthRestore = value;
		return this;
	}

	public function clearHealthRestore():Void {
		hasField__0 &= 0xffff7fff;
		this.healthRestore = 0;
	}

	inline public function hasHealthRestore():PT_Bool {
		return (hasField__0 & 0x8000) != 0;
	}

	public function set_healthRestore(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x8000;
		return this.healthRestore = value;
	}

	public function get_healthRestore():PT_UInt {
		return this.healthRestore;
	}


	/** LABEL_OPTIONAL throttle : TYPE_UINT32 = 42 */
	@:isVar public var throttle(get, set):PT_UInt;
	public inline function setThrottle(value:PT_UInt):GameObject{
		this.throttle = value;
		return this;
	}

	public function clearThrottle():Void {
		hasField__0 &= 0xfffeffff;
		this.throttle = 0;
	}

	inline public function hasThrottle():PT_Bool {
		return (hasField__0 & 0x10000) != 0;
	}

	public function set_throttle(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x10000;
		return this.throttle = value;
	}

	public function get_throttle():PT_UInt {
		return this.throttle;
	}


	/** LABEL_OPTIONAL bars : TYPE_UINT32 = 43 */
	@:isVar public var bars(get, set):PT_UInt;
	public inline function setBars(value:PT_UInt):GameObject{
		this.bars = value;
		return this;
	}

	public function clearBars():Void {
		hasField__0 &= 0xfffdffff;
		this.bars = 0;
	}

	inline public function hasBars():PT_Bool {
		return (hasField__0 & 0x20000) != 0;
	}

	public function set_bars(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x20000;
		return this.bars = value;
	}

	public function get_bars():PT_UInt {
		return this.bars;
	}


	/** LABEL_OPTIONAL emp_for : TYPE_UINT32 = 44 */
	@:isVar public var empFor(get, set):PT_UInt;
	public inline function setEmpFor(value:PT_UInt):GameObject{
		this.empFor = value;
		return this;
	}

	public function clearEmpFor():Void {
		hasField__0 &= 0xfffbffff;
		this.empFor = 0;
	}

	inline public function hasEmpFor():PT_Bool {
		return (hasField__0 & 0x40000) != 0;
	}

	public function set_empFor(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x40000;
		return this.empFor = value;
	}

	public function get_empFor():PT_UInt {
		return this.empFor;
	}


	/** LABEL_OPTIONAL acid_for : TYPE_UINT32 = 45 */
	@:isVar public var acidFor(get, set):PT_UInt;
	public inline function setAcidFor(value:PT_UInt):GameObject{
		this.acidFor = value;
		return this;
	}

	public function clearAcidFor():Void {
		hasField__0 &= 0xfff7ffff;
		this.acidFor = 0;
	}

	inline public function hasAcidFor():PT_Bool {
		return (hasField__0 & 0x80000) != 0;
	}

	public function set_acidFor(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x80000;
		return this.acidFor = value;
	}

	public function get_acidFor():PT_UInt {
		return this.acidFor;
	}


	/** LABEL_OPTIONAL emp_source : TYPE_UINT32 = 61 */
	@:isVar public var empSource(get, set):PT_UInt;
	public inline function setEmpSource(value:PT_UInt):GameObject{
		this.empSource = value;
		return this;
	}

	public function clearEmpSource():Void {
		hasField__0 &= 0xffefffff;
		this.empSource = 0;
	}

	inline public function hasEmpSource():PT_Bool {
		return (hasField__0 & 0x100000) != 0;
	}

	public function set_empSource(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x100000;
		return this.empSource = value;
	}

	public function get_empSource():PT_UInt {
		return this.empSource;
	}


	/** LABEL_OPTIONAL acid_source : TYPE_UINT32 = 62 */
	@:isVar public var acidSource(get, set):PT_UInt;
	public inline function setAcidSource(value:PT_UInt):GameObject{
		this.acidSource = value;
		return this;
	}

	public function clearAcidSource():Void {
		hasField__0 &= 0xffdfffff;
		this.acidSource = 0;
	}

	inline public function hasAcidSource():PT_Bool {
		return (hasField__0 & 0x200000) != 0;
	}

	public function set_acidSource(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x200000;
		return this.acidSource = value;
	}

	public function get_acidSource():PT_UInt {
		return this.acidSource;
	}


	/** LABEL_OPTIONAL stalled : TYPE_BOOL = 54 */
	@:isVar public var stalled(get, set):PT_Bool;
	public inline function setStalled(value:PT_Bool):GameObject{
		this.stalled = value;
		return this;
	}

	public function clearStalled():Void {
		hasField__0 &= 0xffbfffff;
		this.stalled = false;
	}

	inline public function hasStalled():PT_Bool {
		return (hasField__0 & 0x400000) != 0;
	}

	public function set_stalled(value:PT_Bool):PT_Bool{
		hasField__0 |= 0x400000;
		return this.stalled = value;
	}

	public function get_stalled():PT_Bool {
		return this.stalled;
	}


	/** LABEL_OPTIONAL spin : TYPE_SINT32 = 46 */
	@:isVar public var spin(get, set):PT_Int;
	public inline function setSpin(value:PT_Int):GameObject{
		this.spin = value;
		return this;
	}

	public function clearSpin():Void {
		hasField__0 &= 0xff7fffff;
		this.spin = 0;
	}

	inline public function hasSpin():PT_Bool {
		return (hasField__0 & 0x800000) != 0;
	}

	public function set_spin(value:PT_Int):PT_Int{
		hasField__0 |= 0x800000;
		return this.spin = value;
	}

	public function get_spin():PT_Int {
		return this.spin;
	}


	/** LABEL_OPTIONAL controllable : TYPE_BOOL = 47 */
	@:isVar public var controllable(get, set):PT_Bool;
	public inline function setControllable(value:PT_Bool):GameObject{
		this.controllable = value;
		return this;
	}

	public function clearControllable():Void {
		hasField__0 &= 0xfeffffff;
		this.controllable = false;
	}

	inline public function hasControllable():PT_Bool {
		return (hasField__0 & 0x1000000) != 0;
	}

	public function set_controllable(value:PT_Bool):PT_Bool{
		hasField__0 |= 0x1000000;
		return this.controllable = value;
	}

	public function get_controllable():PT_Bool {
		return this.controllable;
	}


	/** LABEL_OPTIONAL controls : TYPE_UINT32 = 48 */
	@:isVar public var controls(get, set):PT_UInt;
	public inline function setControls(value:PT_UInt):GameObject{
		this.controls = value;
		return this;
	}

	public function clearControls():Void {
		hasField__0 &= 0xfdffffff;
		this.controls = 0;
	}

	inline public function hasControls():PT_Bool {
		return (hasField__0 & 0x2000000) != 0;
	}

	public function set_controls(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x2000000;
		return this.controls = value;
	}

	public function get_controls():PT_UInt {
		return this.controls;
	}


	/** LABEL_OPTIONAL powerup : TYPE_ENUM = 49 */
	@:isVar public var powerup(get, set):PT_Int;
	public inline function setPowerup(value:PT_Int):GameObject{
		this.powerup = value;
		return this;
	}

	public function clearPowerup():Void {
		hasField__0 &= 0xfbffffff;
		this.powerup = 0;
	}

	inline public function hasPowerup():PT_Bool {
		return (hasField__0 & 0x4000000) != 0;
	}

	public function set_powerup(value:PT_Int):PT_Int{
		hasField__0 |= 0x4000000;
		return this.powerup = value;
	}

	public function get_powerup():PT_Int {
		return this.powerup;
	}


	/** LABEL_OPTIONAL redPerk : TYPE_ENUM = 50 */
	@:isVar public var redPerk(get, set):PT_Int;
	public inline function setRedPerk(value:PT_Int):GameObject{
		this.redPerk = value;
		return this;
	}

	public function clearRedPerk():Void {
		hasField__0 &= 0xf7ffffff;
		this.redPerk = 0;
	}

	inline public function hasRedPerk():PT_Bool {
		return (hasField__0 & 0x8000000) != 0;
	}

	public function set_redPerk(value:PT_Int):PT_Int{
		hasField__0 |= 0x8000000;
		return this.redPerk = value;
	}

	public function get_redPerk():PT_Int {
		return this.redPerk;
	}


	/** LABEL_OPTIONAL bluePerk : TYPE_ENUM = 51 */
	@:isVar public var bluePerk(get, set):PT_Int;
	public inline function setBluePerk(value:PT_Int):GameObject{
		this.bluePerk = value;
		return this;
	}

	public function clearBluePerk():Void {
		hasField__0 &= 0xefffffff;
		this.bluePerk = 0;
	}

	inline public function hasBluePerk():PT_Bool {
		return (hasField__0 & 0x10000000) != 0;
	}

	public function set_bluePerk(value:PT_Int):PT_Int{
		hasField__0 |= 0x10000000;
		return this.bluePerk = value;
	}

	public function get_bluePerk():PT_Int {
		return this.bluePerk;
	}


	/** LABEL_OPTIONAL greenPerk : TYPE_ENUM = 52 */
	@:isVar public var greenPerk(get, set):PT_Int;
	public inline function setGreenPerk(value:PT_Int):GameObject{
		this.greenPerk = value;
		return this;
	}

	public function clearGreenPerk():Void {
		hasField__0 &= 0xdfffffff;
		this.greenPerk = 0;
	}

	inline public function hasGreenPerk():PT_Bool {
		return (hasField__0 & 0x20000000) != 0;
	}

	public function set_greenPerk(value:PT_Int):PT_Int{
		hasField__0 |= 0x20000000;
		return this.greenPerk = value;
	}

	public function get_greenPerk():PT_Int {
		return this.greenPerk;
	}


	/** LABEL_REPEATED clear_distances : TYPE_UINT32 = 60 */
	@:isVar public var clearDistances(get, set):Array<PT_UInt>;
	public inline function setClearDistances(value:Array<PT_UInt>):GameObject{
		this.clearDistances = value;
		return this;
	}

	public function set_clearDistances(value:Array<PT_UInt>):Array<PT_UInt> {
		return this.clearDistances = value;
	}

	public function get_clearDistances():Array<PT_UInt> {
		return this.clearDistances;
	}

	public function addClearDistances(value:PT_UInt):Void {
		if(this.clearDistances == null) this.clearDistances = [value];
		else this.clearDistances.push(value);
	}

	public function new(){
		super();
		this.clearDistances = [];
	}

	/** @private */
	override public function writeToBuffer(output:PT_OutputStream):Void {
		if (hasUid()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 1);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.uid);
		}
		if (hasType()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 2);
			protohx.WriteUtils.write__TYPE_ENUM(output, this.type);
		}
		if (hasOwner()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 3);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.owner);
		}
		if (hasTeam()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 4);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.team);
		}
		if (hasPositionX()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 10);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.positionX);
		}
		if (hasPositionY()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 11);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.positionY);
		}
		if (hasAngle()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 12);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.angle);
		}
		if (hasScale()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 20);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.scale);
		}
		if (hasFlipX()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 21);
			protohx.WriteUtils.write__TYPE_BOOL(output, this.flipX);
		}
		if (hasFlipY()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 22);
			protohx.WriteUtils.write__TYPE_BOOL(output, this.flipY);
		}
		if (hasCharge()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 30);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.charge);
		}
		if (hasHealPercentage()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 31);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.healPercentage);
		}
		if (hasTimeRemaining()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 32);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.timeRemaining);
		}
		if (hasAmmo()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 40);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.ammo);
		}
		if (hasHealth()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 41);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.health);
		}
		if (hasHealthRestore()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 53);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.healthRestore);
		}
		if (hasThrottle()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 42);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.throttle);
		}
		if (hasBars()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 43);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.bars);
		}
		if (hasEmpFor()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 44);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.empFor);
		}
		if (hasAcidFor()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 45);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.acidFor);
		}
		if (hasEmpSource()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 61);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.empSource);
		}
		if (hasAcidSource()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 62);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.acidSource);
		}
		if (hasStalled()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 54);
			protohx.WriteUtils.write__TYPE_BOOL(output, this.stalled);
		}
		if (hasSpin()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 46);
			protohx.WriteUtils.write__TYPE_SINT32(output, this.spin);
		}
		if (hasControllable()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 47);
			protohx.WriteUtils.write__TYPE_BOOL(output, this.controllable);
		}
		if (hasControls()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 48);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.controls);
		}
		if (hasPowerup()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 49);
			protohx.WriteUtils.write__TYPE_ENUM(output, this.powerup);
		}
		if (hasRedPerk()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 50);
			protohx.WriteUtils.write__TYPE_ENUM(output, this.redPerk);
		}
		if (hasBluePerk()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 51);
			protohx.WriteUtils.write__TYPE_ENUM(output, this.bluePerk);
		}
		if (hasGreenPerk()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 52);
			protohx.WriteUtils.write__TYPE_ENUM(output, this.greenPerk);
		}
		if (this.clearDistances != null) {
			for (value in this.clearDistances) {
				protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 60);
				protohx.WriteUtils.write__TYPE_UINT32(output, value);
			}
		}
		super.writeExtensionOrUnknownFields(output);
	}

	override public function forEachFields(fn:String->Dynamic->Void):Void {
		if (hasUid()) {
			fn("uid", this.uid);
		}
		if (hasType()) {
			fn("type", this.type);
		}
		if (hasOwner()) {
			fn("owner", this.owner);
		}
		if (hasTeam()) {
			fn("team", this.team);
		}
		if (hasPositionX()) {
			fn("positionX", this.positionX);
		}
		if (hasPositionY()) {
			fn("positionY", this.positionY);
		}
		if (hasAngle()) {
			fn("angle", this.angle);
		}
		if (hasScale()) {
			fn("scale", this.scale);
		}
		if (hasFlipX()) {
			fn("flipX", this.flipX);
		}
		if (hasFlipY()) {
			fn("flipY", this.flipY);
		}
		if (hasCharge()) {
			fn("charge", this.charge);
		}
		if (hasHealPercentage()) {
			fn("healPercentage", this.healPercentage);
		}
		if (hasTimeRemaining()) {
			fn("timeRemaining", this.timeRemaining);
		}
		if (hasAmmo()) {
			fn("ammo", this.ammo);
		}
		if (hasHealth()) {
			fn("health", this.health);
		}
		if (hasHealthRestore()) {
			fn("healthRestore", this.healthRestore);
		}
		if (hasThrottle()) {
			fn("throttle", this.throttle);
		}
		if (hasBars()) {
			fn("bars", this.bars);
		}
		if (hasEmpFor()) {
			fn("empFor", this.empFor);
		}
		if (hasAcidFor()) {
			fn("acidFor", this.acidFor);
		}
		if (hasEmpSource()) {
			fn("empSource", this.empSource);
		}
		if (hasAcidSource()) {
			fn("acidSource", this.acidSource);
		}
		if (hasStalled()) {
			fn("stalled", this.stalled);
		}
		if (hasSpin()) {
			fn("spin", this.spin);
		}
		if (hasControllable()) {
			fn("controllable", this.controllable);
		}
		if (hasControls()) {
			fn("controls", this.controls);
		}
		if (hasPowerup()) {
			fn("powerup", this.powerup);
		}
		if (hasRedPerk()) {
			fn("redPerk", this.redPerk);
		}
		if (hasBluePerk()) {
			fn("bluePerk", this.bluePerk);
		}
		if (hasGreenPerk()) {
			fn("greenPerk", this.greenPerk);
		}
		if (this.clearDistances != null && this.clearDistances.length > 0) {
			fn("clearDistances", this.clearDistances);
		}
	}

	/** @private */
	override public function readFromSlice(input:PT_InputStream, bytesAfterSlice:PT_UInt):Void {
		var uid__count:PT_UInt = 0;
		var type__count:PT_UInt = 0;
		var owner__count:PT_UInt = 0;
		var team__count:PT_UInt = 0;
		var position_x__count:PT_UInt = 0;
		var position_y__count:PT_UInt = 0;
		var angle__count:PT_UInt = 0;
		var scale__count:PT_UInt = 0;
		var flipX__count:PT_UInt = 0;
		var flipY__count:PT_UInt = 0;
		var charge__count:PT_UInt = 0;
		var heal_percentage__count:PT_UInt = 0;
		var time_remaining__count:PT_UInt = 0;
		var ammo__count:PT_UInt = 0;
		var health__count:PT_UInt = 0;
		var health_restore__count:PT_UInt = 0;
		var throttle__count:PT_UInt = 0;
		var bars__count:PT_UInt = 0;
		var emp_for__count:PT_UInt = 0;
		var acid_for__count:PT_UInt = 0;
		var emp_source__count:PT_UInt = 0;
		var acid_source__count:PT_UInt = 0;
		var stalled__count:PT_UInt = 0;
		var spin__count:PT_UInt = 0;
		var controllable__count:PT_UInt = 0;
		var controls__count:PT_UInt = 0;
		var powerup__count:PT_UInt = 0;
		var redPerk__count:PT_UInt = 0;
		var bluePerk__count:PT_UInt = 0;
		var greenPerk__count:PT_UInt = 0;
		while (hasBytes(input, bytesAfterSlice)) {
			var tag:PT_UInt = protohx.ReadUtils.read__TYPE_UINT32(input);
			switch (tag >> 3) {
			case 1:
				if (uid__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.uid cannot be set twice.');
				}
				++uid__count;
				this.uid = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 2:
				if (type__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.type cannot be set twice.');
				}
				++type__count;
				this.type = protohx.ReadUtils.read__TYPE_ENUM(input);
			case 3:
				if (owner__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.owner cannot be set twice.');
				}
				++owner__count;
				this.owner = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 4:
				if (team__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.team cannot be set twice.');
				}
				++team__count;
				this.team = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 10:
				if (position_x__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.positionX cannot be set twice.');
				}
				++position_x__count;
				this.positionX = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 11:
				if (position_y__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.positionY cannot be set twice.');
				}
				++position_y__count;
				this.positionY = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 12:
				if (angle__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.angle cannot be set twice.');
				}
				++angle__count;
				this.angle = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 20:
				if (scale__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.scale cannot be set twice.');
				}
				++scale__count;
				this.scale = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 21:
				if (flipX__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.flipX cannot be set twice.');
				}
				++flipX__count;
				this.flipX = protohx.ReadUtils.read__TYPE_BOOL(input);
			case 22:
				if (flipY__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.flipY cannot be set twice.');
				}
				++flipY__count;
				this.flipY = protohx.ReadUtils.read__TYPE_BOOL(input);
			case 30:
				if (charge__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.charge cannot be set twice.');
				}
				++charge__count;
				this.charge = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 31:
				if (heal_percentage__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.healPercentage cannot be set twice.');
				}
				++heal_percentage__count;
				this.healPercentage = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 32:
				if (time_remaining__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.timeRemaining cannot be set twice.');
				}
				++time_remaining__count;
				this.timeRemaining = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 40:
				if (ammo__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.ammo cannot be set twice.');
				}
				++ammo__count;
				this.ammo = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 41:
				if (health__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.health cannot be set twice.');
				}
				++health__count;
				this.health = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 53:
				if (health_restore__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.healthRestore cannot be set twice.');
				}
				++health_restore__count;
				this.healthRestore = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 42:
				if (throttle__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.throttle cannot be set twice.');
				}
				++throttle__count;
				this.throttle = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 43:
				if (bars__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.bars cannot be set twice.');
				}
				++bars__count;
				this.bars = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 44:
				if (emp_for__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.empFor cannot be set twice.');
				}
				++emp_for__count;
				this.empFor = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 45:
				if (acid_for__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.acidFor cannot be set twice.');
				}
				++acid_for__count;
				this.acidFor = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 61:
				if (emp_source__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.empSource cannot be set twice.');
				}
				++emp_source__count;
				this.empSource = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 62:
				if (acid_source__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.acidSource cannot be set twice.');
				}
				++acid_source__count;
				this.acidSource = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 54:
				if (stalled__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.stalled cannot be set twice.');
				}
				++stalled__count;
				this.stalled = protohx.ReadUtils.read__TYPE_BOOL(input);
			case 46:
				if (spin__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.spin cannot be set twice.');
				}
				++spin__count;
				this.spin = protohx.ReadUtils.read__TYPE_SINT32(input);
			case 47:
				if (controllable__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.controllable cannot be set twice.');
				}
				++controllable__count;
				this.controllable = protohx.ReadUtils.read__TYPE_BOOL(input);
			case 48:
				if (controls__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.controls cannot be set twice.');
				}
				++controls__count;
				this.controls = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 49:
				if (powerup__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.powerup cannot be set twice.');
				}
				++powerup__count;
				this.powerup = protohx.ReadUtils.read__TYPE_ENUM(input);
			case 50:
				if (redPerk__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.redPerk cannot be set twice.');
				}
				++redPerk__count;
				this.redPerk = protohx.ReadUtils.read__TYPE_ENUM(input);
			case 51:
				if (bluePerk__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.bluePerk cannot be set twice.');
				}
				++bluePerk__count;
				this.bluePerk = protohx.ReadUtils.read__TYPE_ENUM(input);
			case 52:
				if (greenPerk__count != 0) {
					throw new PT_IOError('Bad data format: GameObject.greenPerk cannot be set twice.');
				}
				++greenPerk__count;
				this.greenPerk = protohx.ReadUtils.read__TYPE_ENUM(input);
			case 60:
				if(this.clearDistances == null) {
					this.clearDistances = [];
				}
				if (cast((tag & 7), PT_UInt) == protohx.WireType.LENGTH_DELIMITED) {
					protohx.ReadUtils.readPackedRepeated(input, protohx.ReadUtils.read__TYPE_UINT32, this.clearDistances);
				} else 				{
					this.clearDistances.push(cast protohx.ReadUtils.read__TYPE_UINT32(input));
				}
			default:
				super.readUnknown(input, tag);
			}
		}
	}

}

