from datetime import time
import torch.utils.data as D
import altitude_rl as arl
import torch as t
from tqdm import tqdm
import wandb
import argparse
from pprint import pprint

parser = argparse.ArgumentParser()
parser.add_argument("--epochs", type=int, default=10)
parser.add_argument("--lr", type=float, default=1e-3)
parser.add_argument("--d", type=int, default=128)
args = parser.parse_args()

wandb.init(
    project="altitude-rl",
    config={"model": "deepish-fixed", **vars(args)},
)

dataset = t.load("data/ffa_channelpark_3.pt", weights_only=False)



d = args.d
model = t.nn.Sequential(
    arl.networks.ObsEncoder3(d=d),
    t.nn.Linear(d, d),
    t.nn.ReLU(),
    t.nn.Linear(d, 1),
    t.nn.Flatten(start_dim=0),
).to(t.float32)

train_loader = D.DataLoader(dataset, batch_size=1024, shuffle=True)
opt = t.optim.SGD(lr=args.lr, params=model.parameters())
loss_fn = t.nn.MSELoss()


for epoch_num in range(args.epochs):
    print(f"Epoch {epoch_num}")
    for i, (x, y) in enumerate(tqdm(train_loader)):
        x=x.float()
        y=y.float()
        train_loss = loss_fn(y, model(x))
        opt.zero_grad()
        train_loss.backward()
        opt.step()

        wandb.log({"train_loss": train_loss.item(), "epoch": epoch_num})

    print("Saving model")
    t.save(model.state_dict(), "data/model.pt")


# wandb.finish()
