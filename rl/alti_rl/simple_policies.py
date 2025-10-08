import numpy as np
import random


class TurningPolicy:
    def __init__(self, rate=3):
        self.possible_actions = [
            np.array([0, 0, 0, 0, 0, 0, 0]),
            np.array([0, 1, 0, 0, 0, 0, 0]),
            np.array([1, 0, 0, 0, 0, 0, 0]),
        ]
        self.action = self.possible_actions[0]
        self.rate = rate

    def act(self) -> np.ndarray:
        if np.random.rand() < self.rate / 30:
            self.action = random.choice(self.possible_actions)
        return self.action
