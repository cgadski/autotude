# %%
%load_ext autoreload
%autoreload 2

# %%
import alti_rl as arl
import vandc
from alti_rl.networks import PlaneEncoder, crash_to_go, plane_features, simple_mlp
import torch
import matplotlib.pyplot as plt
from surgeon_pytorch import Extract, get_layers, get_nodes


# %%
data = torch.load("../data/channelpark.pt")
to_go = crash_to_go(data["reward"])
ob = data["ob"]

idx = torch.arange(to_go.shape[0])
# mask = (idx > 12 * 30) & (idx <= 24 * 30)
mask = (idx > 1) & (idx < 60 * 30)
plt.scatter(ob[mask, 0], data["ob"][mask, 1], c=to_go[mask], s=1)
plt.colorbar()
# %%
f = plane_features(ob[mask])
# plt.scatter(features[:, 0], features[:, 1])

sparse = sparse_pos(f, 20)
plt.matshow(sparse[100:60 * 30])
# plt.matshow(f[:5])

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
