import random
from typing import Any

import numpy as np
import torch
import vandc
from loguru import logger

from alti_rl.networks import NavNet, Options, encode_plane

ACTIONS = [
    np.array([0, 0, 0, 0, 0, 0, 0], dtype=np.int8),  # straight
    np.array([1, 0, 0, 0, 0, 0, 0], dtype=np.int8),  # left
    np.array([0, 1, 0, 0, 0, 0, 0], dtype=np.int8),  # right
]


class Policy:
    def act(self, ob: dict[str, Any]) -> np.ndarray:
        raise NotImplementedError()


class TurningPolicy(Policy):
    def __init__(self, rate=3):
        self.action = ACTIONS[0]
        self.rate = rate

    def act(self, ob: dict) -> np.ndarray:
        if np.random.rand() < self.rate / 30:
            self.action = random.choice(ACTIONS)
        return self.action


class NetPolicy(Policy):
    def __init__(self, vandc_run: str):
        run = vandc.fetch(vandc_run)
        logger.info(f"Loading net policy from {run}")
        opts = Options(**vandc.fetch(vandc_run).config)
        self.model = NavNet(opts)
        self.model.load_state_dict(
            torch.load(f"./models/{vandc_run}.pt", weights_only=True)
        )
        self.model = torch.compile(self.model)
        self.model.eval()
        self.ob_prev = None

        self.action = ACTIONS[0]

    def act(self, ob: dict) -> np.ndarray:
        can_act = (
            (self.ob_prev is not None)
            and (ob.get("x") is not None)
            and (self.ob_prev.get("x") is not None)
        )

        if can_act:
            mask, x = encode_plane(
                x=torch.Tensor([self.ob_prev["x"], ob["x"]]),
                y=torch.Tensor([self.ob_prev["y"], ob["y"]]),
                angle=torch.Tensor([self.ob_prev["angle"], ob["angle"]]),
                alive=torch.ones(2, dtype=torch.bool),
            )

            if mask[1]:
                with torch.no_grad():
                    values = self.model(x[1:2]).squeeze(0)
                self.action = ACTIONS[values.argmin()]

        self.ob_prev = ob.copy()

        return self.action
