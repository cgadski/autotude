# %%
# enable autoreload
%load_ext autoreload
%autoreload 2

# %%
import torch
from alti_rl.networks import encode_plane, exp_discount

# %%
data = torch.load("../data/flying.pt")
mask, plane = encode_plane(**data)
plane[mask].std(dim=0)
# %%
import matplotlib.pyplot as plt

idx = torch.arange(60)
vals = exp_discount(data["damage"], 0.98)
mask = data["alive"][idx]
plt.scatter(
    x=data["x"][idx],
    y=data["y"][idx],
    c=vals[idx],
    alpha=0.1,
)
plt.colorbar()

# %%
# ((data["x"] > 5760 - 20) & (data["y"] > ) & (data["y"] < 90)).argwhere()

# %%
def find_time(x, y):
    dist = (data["x"] - x) ** 2 + (data["y"] - y) ** 2
    torch.argmin(dist)[0]

# %%
import numpy as np

_mask = data["alive"]
_x = data["x"][_mask].numpy()
_y = data["y"][_mask].numpy()

fig, ax = plt.subplots()
fig.set_size_inches((12, 6))
hb = ax.hexbin(_x, _y, gridsize=200, bins="log", cmap="viridis")
fig.colorbar(hb, ax=ax)
ax.set_aspect(1)
plt.scatter([5760], [1870], marker="+", s=100)
plt.show()


# %%
import matplotlib.pyplot as plt
import vandc


def show(run: str):
    plt.plot(vandc.fetch(run).logs[10:], alpha=0.5)

show("say-late-legal-lot")
show("should-final-month-city")
plt.ylim(0,1)
