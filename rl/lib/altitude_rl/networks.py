import torch as t
import torch.functional as f
import numpy as np
from tqdm import tqdm


class PositionEncoder(t.nn.Module):
    def __init__(self, d=128, dtype=t.float):
        super().__init__()
        self.centers = t.nn.Parameter(t.rand((d, 2), dtype=dtype))
        self.radii = t.nn.Parameter(t.ones(d, dtype=dtype))

    def forward(self, x: t.Tensor):
        dist = ((self.centers[None, :, :] - x[:, None, :]) ** 2).sum(dim=-1)
        return t.exp(-10 * self.radii * dist)


class PlaneEncoder(t.nn.Module):
    def __init__(self, d=128):
        super().__init__()
        self.pos_encoder = PositionEncoder(d=d)
        self.angle_encoder = t.nn.Linear(2, d)

    def forward(self, positions, angles, controls):
        return self.pos_encoder(pos) + self.angle_encoder(angle_vec)


class ValueNet(t.nn.Module):
    def __init__(self, d=128):
        super().__init__()
        self.pos_encoder = PositionEncoder(d=d)
        self.angle_encoder = t.nn.Linear(2, d)
        self.act_encoder = t.nn.Linear(7, d)
        self.net = t.nn.Sequential(
            t.nn.Linear(d, 2 * d),
            t.nn.ReLU(),
            t.nn.Linear(2 * d, d),
        )

    def forward(self, obs):
        # angle_encoded = self.angle_encoder(
        #     t.stack([
        #         t.cos(obs[:, -1]),
        #         t.sin(obs[:, -1])
        #     ], axis=-1)
        # )
        return self.net(
            # angle_encoded
            self.pos_encoder(obs[:, :2])
            # + self.act_encoder(acts)
        )

    def fit(self, obs, to_go, iters, lr=3e-3):
        optimizer = t.optim.Adam(self.parameters(), lr)
        self.ls = np.zeros(iters)

        for epoch in tqdm(range(iters)):
            pred = self(obs).flatten()
            loss = t.nn.functional.mse_loss(pred, to_go)
            self.ls[epoch] = loss

            optimizer.zero_grad()
            loss.backward()
            optimizer.step()
