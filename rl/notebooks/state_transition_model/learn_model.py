from datetime import time
import torch.utils.data as D
from torch.utils.data import TensorDataset
import altitude_rl as arl
import torch as t
from tqdm import tqdm
import wandb
import argparse
from pprint import pprint

parser = argparse.ArgumentParser()
parser.add_argument("--epochs", type=int, default=2)
parser.add_argument("--lr", type=float, default=1e-2)
parser.add_argument("--d", type=int, default=128)
args = parser.parse_args()

wandb.init(
    project="altitude-rl",
    config={"model": "deepish-fixed", **vars(args)},
)

dataset = t.load("data/ffa_channelpark.pt", weights_only=False)


d = args.d
window= 10
model = t.nn.Sequential(
    arl.networks.MultiObsEncoder(d=d,window=window),
    t.nn.Linear(d, d),
    t.nn.ReLU(),
    t.nn.Linear(d, 4),
    #t.nn.Flatten(start_dim=0),
).to(t.float32)

train_loader = D.DataLoader(dataset, batch_size=32, shuffle=False)
opt = t.optim.SGD(lr=args.lr, params=model.parameters())
loss_fn = t.nn.MSELoss()


for epoch_num in range(args.epochs):
    print(f"Epoch {epoch_num}")
    for i, (x, y) in enumerate(tqdm(train_loader)):
        x=x.float()
        y=x[window:,:3]
        angles =  10 * y[:, 2] * t.pi / 180
        cosi = t.stack([t.cos(angles), t.sin(angles)], dim=1)
        new_y=t.cat((y[:, :2], cosi), dim=1)

        train_loss = loss_fn(new_y, model(x)[:-1])
        opt.zero_grad()
        train_loss.backward()
        opt.step()

        wandb.log({"train_loss": train_loss.item(), "epoch": epoch_num})

    print("Saving model")
    t.save(model.state_dict(), "data/model.pt")


# wandb.finish()
