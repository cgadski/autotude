import xml.etree.ElementTree as ET
from pathlib import Path


class ClientConfig:
    def __init__(self, user: str, pw: str, server: str):
        self.root = ET.Element("Config")
        self.set(mode="PLAY")
        self.set(record="true")
        self.set(port=27276)
        self.set(accountName=user, accountPassword=pw)
        self.set(server=server, password="")
        self.set(clearDistances="true")

        self.set(plane="LOOPY")
        self.set(red=1)
        self.set(green=1)
        self.set(blue=1)

    def set(self, **kwargs):
        for k, v in kwargs.items():
            self.root.set(k, str(v))

    def write(self, path: Path):
        ET.indent(self.root)
        ET.ElementTree(self.root).write(path, encoding="unicode")
