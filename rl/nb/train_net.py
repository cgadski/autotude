# %%
# enable autoreload
%load_ext autoreload
%autoreload 2

# %%
import torch

from alti_rl.networks import encode_plane, exp_discount

# %%
data = torch.load("../data/flying.pt")
mask, plane = encode_plane(data)
plane[mask].std(dim=0)

# %%
import matplotlib.pyplot as plt

n = 10000
vals = exp_discount(data["damage"], 0.98)
mask = data["mask"]
plane = data["plane"]
plt.scatter(
    x=data["plane"][:, 0][mask][:n],
    y=data["plane"][:, 1][mask][:n],
    c=vals[mask][:n],
    alpha=0.1,
)


# %%

action_index(data["acts"]).bincount()

# %%
import matplotlib.pyplot as plt
import vandc


def show(run: str):
    plt.plot(vandc.fetch(run).logs[10:], alpha=0.5)


# show("expect-add-federal-president")  # without actions
# show("continue-hard-serious-home")  # with actions

show("build-read-private-result")  # higher gamma, no actions
show("build-might-federal-person")  # higher gamma, actions
show("write-natural-international-student")
plt.ylim(0, 1)

# plt.plot(vandc.fetch().logs[10:])
#
