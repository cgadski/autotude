from dataclasses import dataclass

import torch
import torch.nn as nn
from torch.optim.optimizer import ParamsT

from alti_rl.data import DTYPE, N_PLANE_STATE_FEATS


@dataclass
class Options:
    seed: int = 42

    # general params
    n_actions: int = 3  # straight, left, right

    # network params
    d_embed: int = 512
    n_layers: int = 3
    activation: str = "silu"  # "relu" | "tanh" | "silu" | "gelu"
    d_pos: int = 16  # size of position embedding
    n_freqs: int = 10  # octaves of fourier features used for positions

    # optimizer params
    lr: float = 0.0068
    lr_min: float = 0.0  # cosine decay target
    beta1: float = 0.928
    beta2: float = 0.974
    batch_size: int = 1024
    epochs: int = 10

    gamma: float = 0.98  # discount rate


    def optimizer(self, params: ParamsT) -> torch.optim.Optimizer:
        return torch.optim.Adam(
            params,
            lr=self.lr,
            betas=(self.beta1, self.beta2),
        )


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


class PositionEmbed(nn.Module):
    """
    Maps un-normalized map positions to d_embed-dimensional embeddings, using
    multi-octave fourier features of the position (as a fraction of the map
    extent) followed by a small MLP.

    `extent` is the (x, y) size of the map; it is a buffer, so it is saved with
    the model but must be set (see `NavNet.set_extent`) before training.
    """

    def __init__(self, d_embed: int, n_freqs: int, d_hidden: int = 64):
        super().__init__()
        self.register_buffer("extent", torch.ones(2, dtype=DTYPE))
        self.register_buffer("freqs", (2.0 ** torch.arange(n_freqs, dtype=DTYPE)) * torch.pi)
        self.mlp = nn.Sequential(
            nn.Linear(4 * n_freqs, d_hidden, dtype=DTYPE),
            nn.SiLU(),
            nn.Linear(d_hidden, d_embed, dtype=DTYPE),
        )

    def forward(self, pos: torch.Tensor) -> torch.Tensor:
        p = pos.to(DTYPE) / self.extent  # N 2
        phase = p.unsqueeze(-1) * self.freqs  # N 2 n_freqs
        feats = torch.cat([phase.sin(), phase.cos()], dim=-1).flatten(1)  # N 4*n_freqs
        return self.mlp(feats)


class NavNet(nn.Module):
    """
    Predicts a vector of logits (one per action) as a function of the state.

    Takes the raw map position together with the features from `encode_plane_state`.
    """

    def __init__(self, opts: Options):
        super().__init__()
        self.pos_embed = PositionEmbed(opts.d_pos, opts.n_freqs)
        self.mlp = build_mlp(
            opts.d_pos + N_PLANE_STATE_FEATS,
            opts.d_embed,
            opts.n_layers,
            opts.n_actions,
            opts.activation,
        )

    def set_extent(self, extent: torch.Tensor) -> None:
        self.pos_embed.extent.copy_(extent.to(DTYPE))

    def forward(self, pos: torch.Tensor, plane_state: torch.Tensor) -> torch.Tensor:
        # pos: N 2, plane_state: N N_PLANE_STATE_FEATS -> N n_actions
        return self.mlp(torch.cat([self.pos_embed(pos), plane_state.to(DTYPE)], dim=1))
