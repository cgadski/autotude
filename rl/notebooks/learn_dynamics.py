# %%
import altitude_rl as arl
import matplotlib.pyplot as plt
from tqdm import tqdm
import torch as t

# %%
data = t.load("data/channelpark.pt")
act = data["act"][1:]
ob = data["ob"][1:]
reward = data["reward"][:-2]

# %%
d = t.diff(ob[:, :2], dim=0)
d_norm = d.norm(dim=-1)
good_upd = (d_norm != 0) & (reward >= 0)
good_upd[0] = False
good_upd.mean(dtype=t.float)

# %%
plt.hist(d_norm[good_upd], bins=100)
plt.show()

# %%
t.max(ob, dim=0)
