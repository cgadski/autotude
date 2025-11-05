# %%
%load_ext autoreload
%autoreload 2

# %%
import alti_rl as arl
import vandc
import torch
import matplotlib.pyplot as plt


# %%
data = torch.load("../data/channelpark.pt")
obs = data["obs"]
obs.shape

# %%
def bin_pos(obs, res):
    max_vals = obs.max(dim=0).values
    binned_x = torch.bucketize(obs[:, 0], torch.linspace(0, max_vals[0], res))
    binned_y = torch.bucketize(obs[:, 1], torch.linspace(0, max_vals[1], res))
    return torch.stack([binned_x, binned_y], dim=-1)

def has_next(obs):
    vels = obs.to(float).diff(dim=0)[:, :2].norm(dim=1)
    return vels < 42

def transitions(obs):
    res = 64
    binned = bin_pos(obs, res)
    binned = res * binned[:, 1] + binned[:, 0]
# binned: b -> (y x)

accessible = torch.bincount(binned, minlength=res * res) > 0
plt.matshow(accessible.reshape((res, res)))

# %%
trans = torch.stack([binned[:-1], binned[1:]], dim=-1)[next]
trans = res * res * trans[:, 0] + trans[:, 1]
# trans: b -> (y x y' x')

pi = torch.bincount(trans, minlength= res * res * res * res)
pi = pi.reshape(res * res, res * res).contiguous().to(torch.float)
pi.shape
pi_ = torch.linalg.matrix_power(pi, 5).reshape(res * res, res * res) > 0
U, S, _, = torch.svd_lowrank(pi_.to(torch.float), q=64)

# %%
embed = U * S
embed.shape

# %%
