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
parser.add_argument("--epochs", type=int, default=1)
parser.add_argument("--batch_size", type=int, default=1024)
parser.add_argument("--lr", type=float, default=1e-3)
parser.add_argument("--d", type=int, default=128)
parser.add_argument("--window", type=int, default=50)
parser.add_argument("--simple", action="store_true", default=False)
args = parser.parse_args()

wandb.init(
    project="altitude-rl",
    config={"model": "state-prediction", **vars(args)},
)

dataset = t.load("data/ffa_channelpark.pt", weights_only=False)


d = args.d
window = args.window


class MyUnfold(t.nn.Module):
    def __init__(self, window):
        super().__init__()
        self.window = window

    def forward(self, x):
        return x.unfold(dimension=0, size=self.window, step=1).flatten(
            start_dim=1, end_dim=2
        )


def make_model():
    if not args.simple:
        return t.nn.Sequential(
            arl.networks.MultiObsEncoder(d=d, window=window),
            t.nn.Linear(d, d),
            t.nn.ReLU(),
            t.nn.Linear(d, 2),
        ).to(t.float32)
    else:
        return t.nn.Sequential(
            MyUnfold(args.window),  # (b, window * 2)
            t.nn.Linear(window * 2, 2),
        )


model = make_model()


train_loader = D.DataLoader(dataset, batch_size=args.batch_size, shuffle=False)
opt = t.optim.SGD(lr=args.lr, params=model.parameters())
loss_fn = t.nn.MSELoss()


for epoch_num in range(args.epochs):
    print(f"Epoch {epoch_num}")
    for i, (x, y) in enumerate(tqdm(train_loader)):
        if args.simple:
            x = x.float()[:, :2]  # (1024, 3)
        else:
            x = x.float()[:]  # (1024, 5)

        y = x[window:, :2]  # (1024 - window, 2)

        train_loss = loss_fn(y, model(x)[: y.shape[0]])
        opt.zero_grad()
        train_loss.backward()
        opt.step()

        baseline = loss_fn(y, x[window - 1 :, :2][: y.shape[0]])

        wandb.log(
            {
                "train_loss": train_loss.item(),
                "constant_baseline": baseline,
                "epoch": epoch_num,
            }
        )

    print("Saving model")
    t.save(model.state_dict(), "data/model.pt")


# wandb.finish()
