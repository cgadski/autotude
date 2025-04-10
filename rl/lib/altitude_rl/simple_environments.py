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
    Rewards: -2 when it dies, something in range [-1, 0] when it takes damage.
    """

    def __init__(self,goal="survive"):
        config = ServerConfig()
        config.set(map="ffa_channelpark")
        config.add_bot(nick="controlled", team="3")

        self._server = BotServer(config)
        self._obs = np.zeros((3,))

        self.goal = goal

    def _get_obs(self, up: Update):
        geom = self._server.map_geometry
        for o in up.objects:
            if o.type < 5:
                if o.owner == 0:
                    self._obs[0] = o.position_x / (2 * geom.max_x)
                    self._obs[1] = o.position_y / (2 * geom.max_y)
                    self._obs[2] = o.angle / 3600
        return self._obs

    
    def _get_reward(self, up: Update):
        reward = 0
        for e in up.events:
            if e.HasField("damage"):
                if e.damage.target == 0:
                    reward -= e.damage.amount / 2000
            if e.HasField("kill"):
                if e.kill.who_died == 0:
                    reward -= 2
        match self.goal:
            case "reach_position":
                reward -= -0.1
                goal_x = 0.3
                goal_y = 0.5
                tol = 0.025
                obs = self._get_obs(up)
                if (obs[0] < goal_x + tol and obs[0] > goal_x - tol) and (
                    obs[1] < goal_y + tol and obs[1] > goal_y - tol
                ):
                    reward += 10

        return reward

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
        self._server.__exit__()

class DuoChannelparkEnv(SoloChannelparkEnv):

    def __init__(self):
        config = ServerConfig()
        config.set(map="ffa_channelpark")
        config.add_bot(nick="controlled", team="3")
        config.add_baseline_bot(nick="enemy", team="4")

        self._server = BotServer(config)
        self._obs = np.zeros((5,))

    def _get_obs(self, up: Update):
        geom = self._server.map_geometry
        for o in up.objects:
            if o.type < 5:
                if o.owner == 0:
                    self._obs[0] = o.position_x / (2 * geom.max_x)
                    self._obs[1] = o.position_y / (2 * geom.max_y)
                    self._obs[2] = o.angle / 3600
                if o.owner == 1:
                    enemy_x = o.position_x / (2 * geom.max_x)
                    enemy_y = o.position_y / (2 * geom.max_y)
                    self._obs[3] = self._obs[0] - enemy_x
                    self._obs[4] = self._obs[1] - enemy_y
        return self._obs

