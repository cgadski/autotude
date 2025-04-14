from contextlib import AbstractContextManager
from google.protobuf.internal.decoder import _DecodeVarint  # type: ignore
from google.protobuf.internal.encoder import _VarintBytes  # type: ignore
from io import BufferedWriter, BufferedReader
from pathlib import Path
import os
import shutil
import stat
import subprocess
import uuid

from .proto.command_pb2 import Cmd
from .proto.map_geometry_pb2 import MapGeometry
from .proto.update_pb2 import Update
from .client_config import ClientConfig
from .paths import BIN, ALTI_HOME

from .bot_server import ensure_fifo


class OnlineClient:
    command_pipe: BufferedWriter
    update_pipe: BufferedReader
    runtime_path: Path

    map_geometry: MapGeometry

    def __init__(self, config: ClientConfig):
        client_exec = BIN / "client"

        self.alti_home = ALTI_HOME
        self.runtime_path = self.alti_home / "run" / str(uuid.uuid1())

        print(f"Creating runtime directory at {self.runtime_path}")
        self.runtime_path.mkdir(parents=True, exist_ok=True)
        config.write(self.runtime_path / "config.xml")
        command_path = self.runtime_path / "command"
        update_path = self.runtime_path / "update"
        for p in [command_path, update_path]:
            ensure_fifo(p)

        log_path = self.runtime_path / "log"
        with open(log_path, "w") as log:
            self.process = subprocess.Popen(
                [client_exec],
                stdout=log,
                stderr=log,
                env={
                    **os.environ,
                    "ALTI_HOME": self.alti_home,
                    "BOT_RUNTIME": self.runtime_path,
                    "BOT_CONFIG": self.runtime_path / "config.xml",
                },
            )

        print(f"Server started with PID {self.process.pid}")
        with open(self.runtime_path / "pid", "w") as pid_file:
            pid_file.write(str(self.process.pid))

        self.command_pipe = open(command_path, "wb")
        self.update_pipe = open(update_path, "rb")

        print("Now polling client")

    def poll(self):
        print("")
        while True:

    def on_update(self, update: Update) -> Cmd:
        return Cmd()

    def update(self, cmd: Cmd) -> Update:
        self._write_command(cmd)
        return self._read_update()

    def _write_command(self, cmd: Cmd):
        serialized = cmd.SerializeToString()
        self.command_pipe.write(_VarintBytes(len(serialized)))
        self.command_pipe.write(serialized)
        self.command_pipe.flush()

    def _read_update(self) -> Update:
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

    def read_map_load(self, up: Update):
        for event in up.events:
            if event.map_load is not None:
                self.map_geometry = event.map_load.map
