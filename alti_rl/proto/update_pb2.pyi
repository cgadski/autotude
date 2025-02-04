"""
@generated by mypy-protobuf.  Do not edit manually!
isort:skip_file
"""
import builtins
import collections.abc
import game_event_pb2
import game_object_pb2
import google.protobuf.descriptor
import google.protobuf.internal.containers
import google.protobuf.message
import sys

if sys.version_info >= (3, 8):
    import typing as typing_extensions
else:
    import typing_extensions

DESCRIPTOR: google.protobuf.descriptor.FileDescriptor

@typing_extensions.final
class Update(google.protobuf.message.Message):
    DESCRIPTOR: google.protobuf.descriptor.Descriptor

    TIME_FIELD_NUMBER: builtins.int
    OBJECTS_FIELD_NUMBER: builtins.int
    EVENTS_FIELD_NUMBER: builtins.int
    time: builtins.int
    """ticks"""
    @property
    def objects(self) -> google.protobuf.internal.containers.RepeatedCompositeFieldContainer[game_object_pb2.GameObject]: ...
    @property
    def events(self) -> google.protobuf.internal.containers.RepeatedCompositeFieldContainer[game_event_pb2.GameEvent]: ...
    def __init__(
        self,
        *,
        time: builtins.int | None = ...,
        objects: collections.abc.Iterable[game_object_pb2.GameObject] | None = ...,
        events: collections.abc.Iterable[game_event_pb2.GameEvent] | None = ...,
    ) -> None: ...
    def HasField(self, field_name: typing_extensions.Literal["time", b"time"]) -> builtins.bool: ...
    def ClearField(self, field_name: typing_extensions.Literal["events", b"events", "objects", b"objects", "time", b"time"]) -> None: ...

global___Update = Update
