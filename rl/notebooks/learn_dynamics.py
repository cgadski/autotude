# %%
import altitude_rl as arl
import matplotlib.pyplot as plt
from tqdm import tqdm
import torch as t

# %%
data = t.load("data/channelpark.pt")
act = data["act"]
ob = data["ob"]
reward = data["reward"]
episode = -reward.cumsum(0, dtype=t.int)

# %%
plt.scatter(ob[:, 0], ob[:, 1], s=0.01)
plt.show()

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
