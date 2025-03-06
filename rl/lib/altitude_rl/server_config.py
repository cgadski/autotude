import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path
from contextlib import contextmanager

_bot_defaults = {
    "nick": "player",
    "team": "0",
    "type": "CONTROLLED",
    "plane": "LOOPY",
    "red": "0",
    "blue": "1",
    "green": "2",
}


class ServerConfig:
    def __init__(self):
        self.root = ET.Element("Config")
        self.bots = ET.SubElement(self.root, "bots")
        self.set(record="true")
        self.set(connect="true")
        self.set(instantRespawn="true")

    def set(self, **kwargs):
        for k, v in kwargs.items():
            self.root.set(k, str(v))
        return self

    def add_bot(self, **kwargs):
        bot_config = {**_bot_defaults, **kwargs}

        bot = ET.SubElement(self.bots, "BotInstance")
        for k, v in bot_config.items():
            bot.set(k, str(v))

        return self

    def add_baseline_bot(self, **kwargs):
        self.add_bot(**kwargs, **{"type": "EASY"})

    def write(self, path: Path):
        ET.indent(self.root)
        ET.ElementTree(self.root).write(path, encoding="unicode")
