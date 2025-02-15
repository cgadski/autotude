import os
import subprocess
import stat
from pathlib import Path
from typing import Optional, Iterator
from google.protobuf.internal.encoder import _VarintBytes  # type: ignore
from google.protobuf.internal.decoder import _DecodeVarint  # type: ignore
from io import BufferedWriter, BufferedReader

from .proto.command_pb2 import Cmd
from .proto.update_pb2 import Update

def ensure_fifo(path: Path):
    if not os.path.exists(path):
        os.mkfifo(path)
    elif not stat.S_ISFIFO(os.stat(path).st_mode):
        raise ValueError(f"{path} exists but is not a named pipe")

class Controller:
    command_pipe: BufferedWriter
    update_pipe: BufferedReader

    map_load: Update

    def __init__(self, config: str):
        alti_home = os.environ.get('ALTI_HOME')
        if not alti_home:
            raise ValueError("ALTI_HOME not set")

        self.alti_home = Path(alti_home)
        command_path = self.alti_home / "command"
        update_path = self.alti_home / "update"
        for p in [command_path, update_path]:
            ensure_fifo(p)

        log_path = self.alti_home / "server.log"
        with open(log_path, 'w') as log:
            print("Starting server")
            self.process = subprocess.Popen(
                ['server', config],
                stdout=log,
                stderr=log,
            )

        self.command_pipe = open(command_path, 'wb')
        self.update_pipe = open(update_path, 'rb')
        print("Connected to server, waiting for first message")
        self.map_load = self.read_update()
        print("Got map load!")

    def update(self, cmd: Cmd) -> Update:
        self.write_command(cmd)
        return self.read_update()

    def write_command(self, cmd: Cmd):
        serialized = cmd.SerializeToString()
        self.command_pipe.write(_VarintBytes(len(serialized)))
        self.command_pipe.write(serialized)
        self.command_pipe.flush()

    def read_update(self) -> Update:
        buf = bytearray()
        while True:
            byte = self.update_pipe.read(1)
            buf.extend(byte)
            try:
                size, pos = _DecodeVarint(buf, 0)
                break
            except IndexError:
                continue

        message_buf = self.update_pipe.read(size)
        if len(message_buf) != size:
            raise IOError("Incomplete message read")

        update = Update()
        update.ParseFromString(message_buf)
        return update

    def __enter__(self):
        return self

    def __exit__(self, type, val, tb):
        cmd = Cmd()
        cmd.shutdown = True
        self.write_command(cmd)
        self.process.wait(timeout=2)

        self.command_pipe.close()
        self.update_pipe.close()
