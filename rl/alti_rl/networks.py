from dataclasses import dataclass

import torch
import torch.nn as nn

DTYPE = torch.float32


def lag(r: torch.Tensor, t: int):
    res = torch.zeros_like(r)
    res[t:] = r[:-t]
    return res


def crash_to_go(r, gamma: float = 0.87):
    # r: t
    res = torch.zeros_like(r, dtype=DTYPE)
    for _ in range(30 * 30):
        res[:-1] = gamma * res[1:]
        res[lag(r, 2) < 0] = -1
    return 5 * res


@dataclass
class Options:
    """
    Bag of options for everything.
    """

    d_embed: int = 64


VEL_STD = 10
POS_SCALE = 2000


def normalize_plane(
    mask: torch.Tensor, plane: torch.Tensor
) -> tuple[torch.Tensor, torch.Tensor]:
    # mask: T
    # plane: T 3 (x, y, angle) in protobuf units
    mask = mask.clone()
    vel = torch.zeros(plane.shape[0], 2)
    vel[1:] = (plane[1:, :2] - plane[:-1, :2]).to(torch.float32)
    vel_norm = torch.norm(vel, dim=1)
    vel = vel / VEL_STD

    theta = plane[:, 2] * 2 * torch.pi / 3600
    heading = torch.stack([torch.cos(theta), torch.sin(theta)], dim=1)
    position = plane[:, :2] / POS_SCALE

    mask[0] = 0  # don't have velocity
    mask[vel_norm > 50] = 0  # respawn jump
    mask[(plane[:, 0] <= 0) & (plane[:, 1] <= 0)] = 0  # off map
    mask[vel_norm == 0] = 0  # stationary

    return mask, torch.concat(
        [vel, heading, position],
        dim=1,
    )  # T 6


class PlaneEncoder(torch.nn.Module):
    def __init__(self, opts: Options):
        super().__init__()
        self.opts = opts

        self.vel_heading_up: nn.Module = nn.Linear(4, 256, dtype=DTYPE)
        self.vel_heading_down: nn.Module = nn.Linear(256, 64)

    def forward(
        self, mask: torch.Tensor, obs: torch.Tensor
    ) -> tuple[torch.Tensor, torch.Tensor]:
        mask, x = normalize_plane(mask, obs)
        x = x.to(DTYPE)

        x = self.vel_heading_up(x[:, :4])
        x = torch.relu(x)
        x = self.vel_heading_down(x)

        return mask, x


class PlaneRegressor(torch.nn.Module):
    def __init__(self, opts: Options):
        super().__init__()
        self.opts = opts
        self.linear = torch.nn.Linear(64, 1, dtype=DTYPE)

    def forward(self, x):
        return self.linear(self.encode(x)).flatten()
