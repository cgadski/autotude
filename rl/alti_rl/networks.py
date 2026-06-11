from dataclasses import dataclass

import torch
import torch.nn as nn

DTYPE = torch.float32


def lag(r: torch.Tensor, t: int):
    res = torch.zeros_like(r)
    res[t:] = r[:-t]
    return res


def exp_discount(value: torch.Tensor, gamma: float = 0.95) -> torch.Tensor:
    """For each timestep t, compute gamma ** (frames until next nonzero), or 0."""
    T = len(value)
    idx = torch.where(value)[0]
    if len(idx) == 0:
        return torch.zeros(T)
    t = torch.arange(T)
    pos = torch.searchsorted(idx, t)
    has_future = pos < len(idx)
    v = torch.zeros(T)
    v[has_future] = gamma ** (idx[pos[has_future]] - t[has_future]).float()
    return v


@dataclass
class Options:
    seed: int = 42

    # general params
    n_actions: int = 3  # straight, left, right

    # network params
    d_embed: int = 512
    n_layers: int = 3
    activation: str = "silu"  # "relu" | "tanh" | "silu" | "gelu"

    # optimizer params
    lr: float = 0.0068
    lr_min: float = 0.0  # cosine decay target
    beta1: float = 0.928
    beta2: float = 0.974
    batch_size: int = 1024
    epochs: int = 10

    gamma: float = 0.98  # discount rate for damage


VEL_STD = 10
POS_SCALE = 2000


def encode_plane(
    mask: torch.Tensor, plane: torch.Tensor
) -> tuple[torch.Tensor, torch.Tensor]:
    mask = mask.clone()
    vel = torch.zeros(plane.shape[0], 2)
    vel[1:] = (plane[1:, :2] - plane[:-1, :2]).to(torch.float32)
    vel_norm = torch.norm(vel, dim=1)

    theta = plane[:, 2] * 2 * torch.pi / 3600
    heading = torch.stack([torch.cos(theta), torch.sin(theta)], dim=1)
    position = plane[:, :2].float() / POS_SCALE

    mask[0] = 0
    mask[vel_norm > 50] = 0  # respawn jump
    mask[(plane[:, 0] <= 0) & (plane[:, 1] <= 0)] = 0  # off map
    mask[vel_norm == 0] = 0

    return mask, torch.cat([vel / VEL_STD, heading, position], dim=1)  # T 6


def action_index(acts: torch.Tensor) -> torch.Tensor:
    n = acts.shape[0]
    res = torch.zeros(n, dtype=torch.int8)
    res[acts[:, 0] == 1] = 1
    res[acts[:, 1] == 1] = 2
    return res


ACTIVATIONS = {"relu": nn.ReLU, "tanh": nn.Tanh, "silu": nn.SiLU, "gelu": nn.GELU}


def build_mlp(
    d_in: int, d_hidden: int, n_layers: int, d_out: int, activation: str = "relu"
) -> nn.Sequential:
    act = ACTIVATIONS[activation]
    layers: list[nn.Module] = [nn.Linear(d_in, d_hidden, dtype=DTYPE), act()]
    for _ in range(n_layers - 1):
        layers += [nn.Linear(d_hidden, d_hidden, dtype=DTYPE), act()]
    readout = nn.Linear(d_hidden, d_out, dtype=DTYPE)
    readout.weight.data.fill_(0)
    readout.bias.data.fill_(0)
    layers.append(readout)
    return nn.Sequential(*layers)


class NavNet(nn.Module):
    """MLP over plane state. Predicts damage value."""

    def __init__(self, opts: Options):
        super().__init__()
        opts = opts
        self.mlp = build_mlp(
            6, opts.d_embed, opts.n_layers, opts.n_actions, opts.activation
        )

    def forward(self, plane: torch.Tensor) -> torch.Tensor:
        # x: N 6
        return self.mlp(plane.to(DTYPE)).squeeze(-1)  # N acts
