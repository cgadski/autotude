import torch
import torch.functional as f
from dataclasses import dataclass


DTYPE = torch.float16

def lag(r:torch.Tensor, t:int):
    res = torch.zeros_like(r)
    res[t:] = r[:-t]
    return res

def crash_to_go(r, gamma:float = 0.87):
    # r: t
    res = torch.zeros_like(r, dtype=DTYPE)
    for _ in range(30 * 30):
        res[:-1] = gamma * res[1:]
        res[lag(r, 2) < 0] = -1
    return 5 * res

@dataclass
class NetOptions:
    d_embed: int
    pos_range: int = 5000


def plane_features(x):
    m = 2500
    pos = x[:, :2].to(DTYPE)
    pos_scaled = (pos - m) / m
    vel = torch.zeros_like(pos_scaled)
    vel[1:] = pos[1:] - pos[:-1]
    outlier_vel = vel.norm(dim=-1) > 40
    vel[outlier_vel] = 0

    angle = (x[:, 2] * torch.pi / 1800).to(DTYPE)
    cis = torch.stack([torch.cos(angle), torch.sin(angle)], dim=-1)
    return torch.concat([pos_scaled, 0.5 * cis, 0.04 * vel], dim=-1)

def sparse_pos(f, r):
    res = torch.zeros((f.shape[0], r * r))
    x_val = torch.minimum(torch.floor(r * (1 + f[:, 0]) / 2).to(torch.int), torch.tensor(r - 1))
    y_val = torch.minimum(torch.floor(r * (1 + f[:, 1]) / 2).to(torch.int), torch.tensor(r - 1))
    res[torch.arange(f.shape[0]), r * y_val + x_val] = 1
    return res


def simple_mlp():
    return torch.nn.Sequential(
        torch.nn.Linear(6, 1024, dtype=DTYPE),
        torch.nn.ReLU(),
        torch.nn.Linear(1024, 1, dtype=DTYPE),
        torch.nn.Sigmoid(),
        torch.nn.Linear(1, 1, dtype=DTYPE),
    )

class PlaneEncoder(torch.nn.Module):
    def __init__(self, opts:NetOptions):
        super().__init__()
        self.opts = opts
        self.centers = torch.nn.Parameter(torch.rand(opts.d_embed, 2, dtype=DTYPE))
        self.angles = torch.nn.Parameter(torch.rand(opts.d_embed, dtype=DTYPE) * 2 * torch.pi)

    def forward(self, x: torch.Tensor):
        opts = self.opts
        pos = x[:, :2].to(DTYPE) / opts.pos_range
        angle = (x[:, 2] * torch.pi / 1800).to(DTYPE)

        d_sim = torch.cdist(pos, self.centers) ** 2  # b d
        a_sim = 1 - torch.cos(angle[:, None] - self.angles[None, :])  # b d
        emb = torch.exp(- d_sim * 10 - a_sim * 2)
        return emb / emb.norm(dim=-1, keepdim=True)


class PlaneEncoderDumb(torch.nn.Module):
    def __init__(self, opts:NetOptions):
        super().__init__()
        self.opts = opts
        self.weight = torch.nn.Linear(4, opts.d_embed, dtype=DTYPE)

    def forward(self, x: torch.Tensor):
        opts = self.opts
        m = opts.pos_range / 2
        pos = (x[:, :2].to(DTYPE) - m) / m
        angle = (x[:, 2] * torch.pi / 1800).to(DTYPE)
        vel = torch.zeros_like(pos)
        vel[:1] = pos[1:]
        cis = torch.stack([torch.cos(angle), torch.sin(angle)], dim=-1)
        pre = torch.concat([pos, cis], dim=-1)
        return torch.relu(self.weight(pre))


class PlaneRegressor(torch.nn.Module):
    def __init__(self, opts:NetOptions):
        super().__init__()
        self.opts = opts
        self.encode = PlaneEncoder(opts).requires_grad_(False)
        self.linear = torch.nn.Linear(opts.d_embed, 1, dtype=DTYPE)

    def forward(self, x):
        return self.linear(self.encode(x)).flatten()
