# -*- coding: utf-8 -*-
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# NO CHECKED-IN PROTOBUF GENCODE
# source: game_object.proto
# Protobuf Python Version: 5.28.3
"""Generated protocol buffer code."""
from google.protobuf import descriptor as _descriptor
from google.protobuf import descriptor_pool as _descriptor_pool
from google.protobuf import runtime_version as _runtime_version
from google.protobuf import symbol_database as _symbol_database
from google.protobuf.internal import builder as _builder
_runtime_version.ValidateProtobufRuntimeVersion(
    _runtime_version.Domain.PUBLIC,
    5,
    28,
    3,
    '',
    'game_object.proto'
)
# @@protoc_insertion_point(imports)

_sym_db = _symbol_database.Default()




DESCRIPTOR = _descriptor_pool.Default().AddSerializedFile(b'\n\x11game_object.proto\"\xb8\x04\n\nGameObject\x12\x0b\n\x03uid\x18\x01 \x01(\r\x12\x19\n\x04type\x18\x02 \x01(\x0e\x32\x0b.ObjectType\x12\r\n\x05owner\x18\x03 \x01(\r\x12\x0c\n\x04team\x18\x04 \x01(\r\x12\x12\n\nposition_x\x18\n \x01(\r\x12\x12\n\nposition_y\x18\x0b \x01(\r\x12\r\n\x05\x61ngle\x18\x0c \x01(\r\x12\r\n\x05scale\x18\x14 \x01(\r\x12\r\n\x05\x66lipX\x18\x15 \x01(\x08\x12\r\n\x05\x66lipY\x18\x16 \x01(\x08\x12\x0e\n\x06\x63harge\x18\x1e \x01(\r\x12\x17\n\x0fheal_percentage\x18\x1f \x01(\r\x12\x16\n\x0etime_remaining\x18  \x01(\r\x12\x0c\n\x04\x61mmo\x18( \x01(\r\x12\x0e\n\x06health\x18) \x01(\r\x12\x16\n\x0ehealth_restore\x18\x35 \x01(\r\x12\x10\n\x08throttle\x18* \x01(\r\x12\x0c\n\x04\x62\x61rs\x18+ \x01(\r\x12\x0f\n\x07\x65mp_for\x18, \x01(\r\x12\x10\n\x08\x61\x63id_for\x18- \x01(\r\x12\x0f\n\x07stalled\x18\x36 \x01(\x08\x12\x0c\n\x04spin\x18. \x01(\x11\x12\x14\n\x0c\x63ontrollable\x18/ \x01(\x08\x12\x10\n\x08\x63ontrols\x18\x30 \x01(\r\x12\x1c\n\x07powerup\x18\x31 \x01(\x0e\x32\x0b.ObjectType\x12\x16\n\x07redPerk\x18\x32 \x01(\x0e\x32\x05.Perk\x12\x17\n\x08\x62luePerk\x18\x33 \x01(\x0e\x32\x05.Perk\x12\x18\n\tgreenPerk\x18\x34 \x01(\x0e\x32\x05.Perk\x12\x17\n\x0f\x63lear_distances\x18< \x03(\r*\x89\x05\n\nObjectType\x12\x13\n\x0eUNKNOWN_OBJECT\x10\x80\x01\x12\t\n\x05LOOPY\x10\x00\x12\n\n\x06\x42OMBER\x10\x01\x12\x0c\n\x08\x45XPLODET\x10\x02\x12\x0b\n\x07\x42IPLANE\x10\x03\x12\x0b\n\x07MIRANDA\x10\x04\x12\x12\n\x0eMISSLE_POWERUP\x10\n\x12\x12\n\x0eSHIELD_POWERUP\x10\x0b\x12\x10\n\x0cWALL_POWERUP\x10\x0c\x12\x14\n\x10\x42IG_BOMB_POWERUP\x10\r\x12\x08\n\x04\x42\x41LL\x10\x0e\x12\x12\n\x0eHEALTH_POWERUP\x10\x0f\x12\x13\n\x0fPOWERUP_SPAWNER\x10\x10\x12\x16\n\x12\x44OUBLE_FIRE_MISSLE\x10\x14\x12\x12\n\x0eTRACKER_MISSLE\x10\x15\x12\x0f\n\x0b\x45MP_CAPSULE\x10\x16\x12\x11\n\rEMP_EXPLOSION\x10\x17\x12\r\n\tACID_BOMB\x10\x18\x12\x0e\n\nACID_CLOUD\x10\x19\x12\x08\n\x04NADE\x10\x1e\x12\x08\n\x04\x46LAK\x10\x1f\x12\x0e\n\nSUPPRESSOR\x10 \x12\x08\n\x04\x44OMB\x10!\x12\x13\n\x0f\x42IPLANE_PRIMARY\x10(\x12\x15\n\x11\x42IPLANE_SECONDARY\x10)\x12\x10\n\x0cHEAVY_CANNON\x10*\x12\x13\n\x0f\x44IRECTOR_ROCKET\x10\x32\x12\x16\n\x12THERMOBARIC_ROCKET\x10\x33\x12\x0f\n\x0bREMOTE_MINE\x10\x34\x12\x11\n\rDIRECTOR_MINE\x10\x35\x12\t\n\x05LASER\x10<\x12\x12\n\x0eTRICKSTER_SHOT\x10=\x12\x0e\n\nLASER_SHOT\x10>\x12\x11\n\rHOMING_MISSLE\x10\x46\x12\x08\n\x04WALL\x10G\x12\n\n\x06SHIELD\x10H\x12\x0c\n\x08\x42IG_BOMB\x10I\x12\x08\n\x04GOAL\x10J\x12\x08\n\x04\x42\x41SE\x10K*\xb2\x04\n\x04Perk\x12\x13\n\x0fR_LOOPY_TRACKER\x10\x00\x12\x17\n\x13R_LOOPY_DOUBLE_FIRE\x10\x01\x12\x15\n\x11R_LOOPY_ACID_BOMB\x10\x02\x12\x17\n\x13R_BOMBER_SUPPRESSOR\x10\x03\x12\x12\n\x0eR_BOMBER_BOMBS\x10\x04\x12\x19\n\x15R_BOMBER_FLAK_TAILGUN\x10\x05\x12\x17\n\x13R_EXPLODET_DIRECTOR\x10\x06\x12\"\n\x1eR_EXPLODET_THERMOBARIC_ROCKETS\x10\x07\x12\x1a\n\x16R_EXPLODET_REMOTE_MINE\x10\x08\x12\x18\n\x14R_BIPLANE_DOGFIGHTER\x10\t\x12\x1c\n\x18R_BIPLANE_RECOILLESS_GUN\x10\n\x12\x1a\n\x16R_BIPLANE_HEAVY_CANNON\x10\x0b\x12\x17\n\x13R_MIRANDA_TRICKSTER\x10\x0c\x12\x13\n\x0fR_MIRANDA_LASER\x10\r\x12\x19\n\x15R_MIRANDA_TIME_ANCHOR\x10\x0e\x12\x15\n\x11G_RUBBERIZED_HULL\x10\x0f\x12\x11\n\rG_HEAVY_ARMOR\x10\x10\x12\x12\n\x0eG_REPAIR_DRONE\x10\x11\x12\x14\n\x10G_FLEXIBLE_WINGS\x10\x12\x12\x12\n\x0e\x42_TURBOCHARGER\x10\x13\x12\x14\n\x10\x42_ULTRACAPACITOR\x10\x14\x12\x14\n\x10\x42_REVERSE_THRUST\x10\x15\x12\x13\n\x0f\x42_ACE_INSTINCTS\x10\x16\x42\x1b\n\x17\x65m.altitude.game.protosP\x01')

_globals = globals()
_builder.BuildMessageAndEnumDescriptors(DESCRIPTOR, _globals)
_builder.BuildTopDescriptorsAndMessages(DESCRIPTOR, 'game_object_pb2', _globals)
if not _descriptor._USE_C_DESCRIPTORS:
  _globals['DESCRIPTOR']._loaded_options = None
  _globals['DESCRIPTOR']._serialized_options = b'\n\027em.altitude.game.protosP\001'
  _globals['_OBJECTTYPE']._serialized_start=593
  _globals['_OBJECTTYPE']._serialized_end=1242
  _globals['_PERK']._serialized_start=1245
  _globals['_PERK']._serialized_end=1807
  _globals['_GAMEOBJECT']._serialized_start=22
  _globals['_GAMEOBJECT']._serialized_end=590
# @@protoc_insertion_point(module_scope)
