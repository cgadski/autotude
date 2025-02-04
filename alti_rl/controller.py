import os
from pathlib import Path
from typing import Optional, Iterator
from google.protobuf.internal.encoder import _VarintBytes  # type: ignore
from google.protobuf.internal.decoder import _DecodeVarint  # type: ignore
from alti_rl.proto.update_pb2 import Update

class Controller:
    def __init__(self, server_dir: Optional[str] = None):
        if server_dir is None:
            server_dir = os.environ.get('SERVER_DIR')
            if not server_dir:
                raise ValueError("SERVER_DIR environment variable not set")

        self.server_dir = Path(server_dir)
        self.in_pipe_path = self.server_dir / "server_in"
        self.out_pipe_path = self.server_dir / "server_out"

        if not self.in_pipe_path.exists():
            raise FileNotFoundError(f"Input pipe not found at {self.in_pipe_path}")
        if not self.out_pipe_path.exists():
            raise FileNotFoundError(f"Output pipe not found at {self.out_pipe_path}")

        self.in_pipe = open(self.in_pipe_path, 'wb')
        self.out_pipe = open(self.out_pipe_path, 'rb')

    def send_command(self, command) -> None:
        serialized = command.SerializeToString()
        self.in_pipe.write(_VarintBytes(len(serialized)))
        self.in_pipe.write(serialized)
        self.in_pipe.flush()

    def read_update(self) -> Update:
        buf = bytearray()
        while True:
            byte = self.out_pipe.read(1)
            buf.extend(byte)
            try:
                size, pos = _DecodeVarint(buf, 0)
                break
            except IndexError:
                continue

        message_buf = self.out_pipe.read(size)
        if len(message_buf) != size:
            raise IOError("Incomplete message read")

        update = Update()
        update.ParseFromString(message_buf)
        return update

    def __enter__(self):
        return self

    def __exit__(self, type, val, tb):
        self.in_pipe.close()
        self.out_pipe.close()
