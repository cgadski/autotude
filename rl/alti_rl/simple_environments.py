import numpy as np

from .bot_server import BotServer
from .proto.command_pb2 import Cmd
from .proto.update_pb2 import Update
from .server_config import ServerConfig


def get_solo_obs(update: Update):
    obs = {}

    for object in update.objects:
        if object.type < 5 and object.controllable:
            obs["alive"] = True
            obs["x"] = object.position_x
            obs["y"] = object.position_y
            obs["angle"] = object.angle
            obs["stalled"] = object.stalled
            obs["throttle"] = object.throttle
            obs["ammo"] = object.ammo

    for e in update.events:
        if e.HasField("kill"):
            obs["kill"] = True
        if e.HasField("damage"):
            obs["damage"] = True

    return obs


class SoloEnv:
    """
    Fly on a map alone, return dict of features.
    """

    def __init__(self, *, map="ffa_channelpark"):
        config = ServerConfig()
        config.set(map=map)
        config.add_bot(nick="controlled", team="3")

        self._server = BotServer(config)
        self._obs = {}

    def step(self, action):
        cmd = Cmd()
        action = (action > 0.5).astype(int)
        cmd.inputs[0].controls = np.dot(action, 2 ** np.arange(7))
        update = self._server.update(cmd)
        return get_solo_obs(update)

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self._server.__exit__(exc_type, exc_val, exc_tb)


class LostcityEnv:
    def __init__(self, *, map="tdm_lostcity"):
        config = ServerConfig()
        config.set(map=map)

        teams = [3] * 3 + [4] * 2
        for i, t in enumerate(teams):
            config.add_bot(nick=f"bot {i}", type="EASY", team=t)

        config.add_bot(nick="controlled", type="EXPERT", team=4)

        self._server = BotServer(config)

    def step(self):
        cmd = Cmd()
        up = self._server.update(cmd)

        reward = 0

        for e in up.events:
            if e.WhichOneof("event") == "kill":
                if e.kill.who_died == 5:
                    reward -= 1
                if e.kill.who_killed == 5:
                    reward += 1

        return reward

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self._server.__exit__(exc_type, exc_val, exc_tb)
