import torch.utils.data as D
import torch as t
from tqdm import tqdm
import wandb


wandb.init(
    project="altitude-rl",
    config={"model": "deepish-fixed"},
)

dataset = t.load("data/ffa_channelpark.pt", weights_only=False)

loss_fn = t.nn.MSELoss()
window = 1
train_loader = D.DataLoader(dataset, batch_size=1024, shuffle=False)
for i, (x, r) in enumerate(tqdm(train_loader)):
        x=x.float()
        y= x[window:,:2]
        v = x[window-1:-1,:2] - x[:-window,:2]
        x=x[window-1:-1,:2]
        train_loss = loss_fn(y, x+v)
        wandb.log({"train_loss": train_loss.item(), "epoch": 1})




