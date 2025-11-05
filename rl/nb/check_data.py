# %%
%load_ext autoreload
%autoreload 2

# %%
from os import POSIX_SPAWN_CLOSE
import alti_rl as arl
import vandc
from alti_rl.networks import PlaneEncoder, crash_to_go, plane_features, simple_mlp, sparse_pos
import torch
import matplotlib.pyplot as plt
from surgeon_pytorch import Extract, get_layers, get_nodes


# %%
data = torch.load("../data/channelpark.pt")
to_go = crash_to_go(data["reward"])
obs = data["ob"]

idx = torch.arange(to_go.shape[0])
mask = (idx > 1) & (idx < 60 *  30)
plt.scatter(ob[mask, 0], data["ob"][mask, 1], c=to_go[mask], s=1)
plt.colorbar()

# %%
def bin_pos(obs, res):
    max_vals = obs.max(dim=0).values
    binned_x = torch.bucketize(ob[:, 0], torch.linspace(0, max_vals[0], res))
    binned_y = torch.bucketize(ob[:, 1], torch.linspace(0, max_vals[1], res))
    return torch.stack([binned_x, binned_y], dim=-1)

res = 128
mat = torch.zeros((res, res))
binned = bin_pos(obs, res)
mat[res - binned[:, 1] - 1, binned[:, 0]] = 1
plt.matshow(mat)

# %%
mlp = simple_mlp()
get_nodes(mlp)
data = Extract(mlp, node_out="1")(plane_features(data["ob"][mask]))
plt.matshow(data.data)

# %%
from alti_rl.networks import NetOptions, PlaneEncoder
net_opts = NetOptions(d_embed=128)
encoder = PlaneEncoder(net_opts)

# %%
ob = data["ob"][2:1000]
d = encoder(ob).data
plt.scatter(ob[:, 0], ob[:, 1], c=d @ d[100])
plt.colorbar()

# %%
plt.hist((d[100] @ d.T).data)

# %%
df = vandc.fetch()
plt.plot(df.logs["train_loss"])

# %%
from learn_q import Options
run = vandc.fetch()
net_opts = Options(**run.config).net_options()
state = t.load(f"../models/{run.meta['run']}")
model = arl.networks.PlaneRegressor(net_opts)
model.load_state_dict(state)

# data = t.load("../data/channelpark.pt")
to_go = crash_to_go(data["reward"])
pred = model(data["ob"])
idx = t.arange(to_go.shape[0])
mask = (idx > 1) & (idx <= 60 * 30)

plt.plot(to_go[mask])
plt.plot(pred[mask].data)
