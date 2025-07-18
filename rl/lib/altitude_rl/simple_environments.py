from .bot_server import BotServer
from .server_config import ServerConfig
from .proto.update_pb2 import Update
from .proto.command_pb2 import Cmd

from typing import Optional
import numpy as np


class SoloChannelparkEnv:
    """
    A bot flying solo on ffa_channelpark.

    Observations: its position and bearing.
    Actions: binary vector of controls.
    Rewards: -1 when it dies, 0 otherwise.
    """

    def __init__(self):
        config = ServerConfig()
        config.set(map="ffa_channelpark")
        config.add_bot(nick="controlled", team="3")

        self._server = BotServer(config)
        self._obs = np.zeros((3,))

    def _get_obs(self, up: Update):
        geom = self._server.map_geometry
        for o in up.objects:
            if o.type < 5:
                self._obs[0] = o.position_x
                self._obs[1] = o.position_y
                self._obs[2] = o.angle / 3600
        return self._obs

    def _get_reward(self, up: Update):
        for e in up.events:
            if e.HasField("kill"):
                if e.kill.who_died == 0:
                    return -1
        return 0

    def step(self, action):
        cmd = Cmd()
        action = (action > 0.5).astype(int)
        cmd.inputs[0].controls = np.dot(action, 2 ** np.arange(7))
        up = self._server.update(cmd)

        observation = self._get_obs(up)
        reward = self._get_reward(up)

        return observation, reward

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self._server.__exit__(exc_type, exc_val, exc_tb)
