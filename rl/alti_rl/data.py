import torch


DTYPE = torch.float32
VEL_STD = 10

# velocity (2), heading (2), stalled (1), throttle (1)
N_PLANE_STATE_FEATS = 6


def encode_plane_state(
    x: torch.Tensor,
    y: torch.Tensor,
    angle: torch.Tensor,
    alive: torch.Tensor,
    stalled: torch.Tensor,
    throttle: torch.Tensor,
    **_,
) -> tuple[torch.Tensor, torch.Tensor]:
    """
    Given a sequence of observations from the game, return normalized features to use for training, and
    a mask indicating the indices where these features are available/well-defined.

    These features do not provide absolute position of the plane!
    """
    pos = torch.stack([x, y], 1).to(DTYPE)  # N 2 (float, so differences can't overflow int16)
    angle = angle.to(DTYPE) * 2 * torch.pi / 3600
    N = alive.shape[0]

    vel = torch.zeros(N, 2)
    vel[1:] = pos[1:] - pos[:-1]
    vel_norm = torch.norm(vel, dim=1)
    vel_scaled = vel / VEL_STD

    heading = torch.stack([torch.cos(angle), torch.sin(angle)], dim=1)

    mask = alive.clone()
    mask[0] = 0
    mask[1:] &= alive[:-1]  # velocity needs a live previous frame
    mask[vel_norm > 50] = 0  # respawn jump
    mask[(pos[:, 0] <= 0) & (pos[:, 1] <= 0)] = 0  # off map
    mask[vel_norm == 0] = 0

    return mask, torch.cat(
        [
            vel_scaled,
            heading,
            stalled.to(DTYPE).unsqueeze(1),
            (throttle.to(DTYPE) / 1000).unsqueeze(1),  # throttle max is 1000
        ],
        dim=1,
    )  # N N_PLANE_STATE_FEATS


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
