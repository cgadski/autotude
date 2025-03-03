from .bot_server import BotServer
from .server_config import ServerConfig
from .proto.update_pb2 import Update
from .proto.command_pb2 import Cmd

from typing import Optional
import gymnasium as gym
import numpy as np

class FreeForAllEnv(gym.Env):
    def __init__(self):
        config = ServerConfig()
        config.set(map='ffa_cave')
        config.add_bot(nick='controlled', team='3')
        config.add_baseline_bot(nick='enemy', team='4')

        self.action_space = gym.spaces.MultiBinary(7)
        self.observation_space = gym.spaces.Box(0, 1, shape=(2, 3))

        self._server = BotServer(config)
        self._obs = np.zeros((2, 3))

    def _get_obs(self, up:Update):
        geom = self._server.map_geometry
        i = 0
        for o in up.objects:
            if o.type < 5:
                self._obs[o.owner, 0] = o.position_x / (2 * geom.max_x)
                self._obs[o.owner, 1] = o.position_y / (2 * geom.max_y)
                self._obs[o.owner, 2] = o.angle / 3600
        return self._obs

    def _get_reward(self, up:Update):
        for e in up.events:
            pass
        return 0

    def step(self, action):
        cmd = Cmd()
        cmd.inputs[0].controls = np.dot(action, 2 ** np.arange(7))
        up = self._server.update(cmd)

        observation = self._get_obs(up)
        terminated = False
        truncated = False
        reward = self._get_reward(up)

        return observation, reward, terminated, truncated, {}

    def reset(self, seed: Optional[int] = None, options: Optional[dict] = None):
        cmd = Cmd()
        up = self._server.update(cmd)
        return self._get_obs(up), {}

    def close(self):
        self._server.__exit__()
