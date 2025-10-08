from datetime import time
import torch.utils.data as D
import alti_rl as arl
import torch as t
from tqdm import tqdm
import vandc
import argparse
from pprint import pprint
from simple_parsing import parse
from dataclasses import dataclass

from alti_rl.networks import plane_features

@dataclass
class Options:
    epochs: int = 10
    b: int = 2 ** 12
    d: int = 128
    lr: float = 1e-3

    def net_options(self):
        return arl.networks.NetOptions(
            d_embed = self.d,
            pos_range = 5000
        )


DTYPE = arl.networks.DTYPE

def go(opts: Options):
    # model = arl.networks.PlaneRegressor(opts.net_options())
    model = arl.networks.simple_mlp()

    data = t.load("data/channelpark.pt")
    to_go = arl.networks.crash_to_go(data["reward"])
    dataset = D.TensorDataset(plane_features(data["ob"]), to_go)

    train_loader = D.DataLoader(dataset, batch_size=opts.b, shuffle=False)
    opt = t.optim.SGD(lr=opts.lr, params=model.parameters())
    loss_fn = t.nn.MSELoss()

    baseline = loss_fn(to_go, t.ones_like(to_go) * to_go.mean())
    print(f"baseline: {baseline}")

    for _ in range(opts.epochs):
        for x, to_go in vandc.progress(train_loader):
            train_loss = loss_fn(to_go, model(x).flatten())
            opt.zero_grad()
            train_loss.backward()
            opt.step()
            vandc.log({"train_loss": train_loss/baseline})

    # t.save(model.state_dict(), f"models/{vandc.run_name()}")

if __name__ == "__main__":
    opts = parse(Options)
    vandc.init(opts)
    go(opts)
