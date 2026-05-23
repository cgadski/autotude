import numpy as np

from .bot_server import BotServer
from .proto.command_pb2 import Cmd
from .proto.update_pb2 import Update
from .server_config import ServerConfig


class SoloEnv:
    """
    Flying solo on a map. Reward model: taking crash damage.
    """

    def __init__(self, *, map="ffa_channelpark"):
        config = ServerConfig()
        config.set(map=map)
        config.add_bot(nick="controlled", team="3")

        self._server = BotServer(config)
        self._obs = np.zeros((3,), dtype=np.int16)

    def _get_obs(self, up: Update):
        for o in up.objects:
            if o.type < 5:
                self._obs[0] = o.position_x
                self._obs[1] = o.position_y
                self._obs[2] = o.angle
        return self._obs

    def _get_reward(self, up: Update):
        for e in up.events:
            if e.HasField("damage"):
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
