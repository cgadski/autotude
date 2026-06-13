# %%
import torch
import alti_rl.networks as nets
import matplotlib.pyplot as plt

# %%
# run = "build-show-general-hour"
run = "write-natural-international-student"
net = nets.NavNet(nets.Options())

net.load_state_dict(torch.load(f"../models/{run}.pt"))

data = torch.load("../data/flying.pt", weights_only=True)
mask, plane = nets.encode_plane(data["mask"], data["plane"])
N = plane.shape[0]
idx = torch.arange(N)[:100]

pred = net(plane[mask][idx])
for i in range(3):
    plt.plot(pred[:, i].data)
