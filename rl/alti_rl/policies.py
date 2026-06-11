import random

import numpy as np
import torch

from alti_rl.networks import NavNet, Options, encode_plane

ACTIONS = [
    np.array([0, 0, 0, 0, 0, 0, 0], dtype=np.int8),  # straight
    np.array([1, 0, 0, 0, 0, 0, 0], dtype=np.int8),  # left
    np.array([0, 1, 0, 0, 0, 0, 0], dtype=np.int8),  # right
]


class TurningPolicy:
    def __init__(self, rate=3):
        self.action = self.possible_actions[0]
        self.rate = rate

    def act(self) -> np.ndarray:
        if np.random.rand() < self.rate / 30:
            self.action = random.choice(ACTIONS)
        return self.action


class NetPolicy:
    def __init__(self, model_path: str, opts: Options = None):
        self.model = NavNet(opts or Options())
        self.model.load_state_dict(torch.load(model_path, weights_only=True))
        self.model.eval()
        self.prev_ob: dict | None = None

    @staticmethod
    def obs_to_numpy(ob: dict) -> np.ndarray | None:
        if not ob.get("x"):
            return None
        return np.array([ob["x"], ob["y"], ob["angle"]], dtype=np.int16)

    def act(self, ob: dict) -> np.ndarray:
        action = ACTIONS[0]
        ob_np = self.obs_to_numpy(ob)

        if ob_np is not None and self.prev_ob is not None:
            prev = torch.tensor(
                [self.prev_ob["x"], self.prev_ob["y"], self.prev_ob["angle"]],
                dtype=torch.int16,
            )
            cur = torch.tensor(ob_np, dtype=torch.int16)
            mask, x = encode_plane(
                torch.ones(2, dtype=torch.bool), torch.stack([prev, cur])
            )
            if mask[1]:
                with torch.no_grad():
                    values = self.model(x[1:2])  # (1, n_actions)
                action = ACTIONS[values.squeeze(0).argmin().item()]

        if ob_np is not None:
            self.prev_ob = ob

        return action
