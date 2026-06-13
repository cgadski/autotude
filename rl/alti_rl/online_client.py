import os
import subprocess
import uuid
from io import BufferedReader, BufferedWriter
from pathlib import Path
from typing import Union

from google.protobuf.internal.decoder import _DecodeVarint  # type: ignore
from google.protobuf.internal.encoder import _VarintBytes  # type: ignore
from loguru import logger

from .bot_server import ensure_fifo
from .client_config import ClientConfig
from .paths import ALTI_HOME, BIN
from .proto.command_pb2 import ClientCmd
from .proto.map_geometry_pb2 import MapGeometry
from .proto.update_pb2 import Update


class OnlineClient:
    command_pipe: BufferedWriter
    update_pipe: BufferedReader
    runtime_path: Path

    map_geometry: Union[MapGeometry, None] = None

    def __init__(self, config: ClientConfig):
        client_exec = BIN / "bot_client"

        self.alti_home = ALTI_HOME
        self.runtime_path = self.alti_home / "run" / str(uuid.uuid1())

        logger.info(f"Creating runtime directory at {self.runtime_path}")
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

        logger.info(f"Client started with PID {self.process.pid}")
        with open(self.runtime_path / "pid", "w") as pid_file:
            pid_file.write(str(self.process.pid))

        self.command_pipe = open(command_path, "wb")
        self.update_pipe = open(update_path, "rb")

        logger.info("Pipes open, now polling client")

    def poll(self):
        updates = 0

        while True:
            if self.process.poll() is not None:
                logger.error(
                    f"Client process exited with code {self.process.returncode}"
                )
                raise RuntimeError(f"Client exited")

            update = self._read_update()
            if len(update.events) > 0:
                logger.debug(update.events.__repr__())

            for event in update.events:
                if event.WhichOneof("event") == "map_load":
                    self.map_geometry = event.map_load.map
                    logger.info(
                        f"Loaded {event.map_load.name}: dimensions {self.map_geometry.max_x}x{self.map_geometry.max_y}"
                    )
            self._write_command(self.on_update(update))
            updates += 1
            if updates % (300) == 0:
                logger.debug(
                    f"Client running: processed {updates} updates ({updates // 30}s)"
                )

    def on_update(self, update: Update) -> ClientCmd:
        return ClientCmd()

    def _write_command(self, cmd: ClientCmd):
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
