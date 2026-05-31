# %%
import torch

from alti_rl.networks import Options, PlaneEncoder, normalize_plane

# %%
data = torch.load("../data/flying.pt")
batch = 1024
# data["mask"].sum()
mask = data["mask"][:batch]
plane = data["plane"][:batch]
_, normed = normalize_plane(data["mask"], data["plane"])

enc = PlaneEncoder(Options())
mask, x = enc(mask, plane)
x.shape  # 1024, 64

# %%
import matplotlib.pyplot as plt

# %%
plt.matshow(x[mask].data[128 : 128 + 256].T)
