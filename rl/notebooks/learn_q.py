# ---
# jupyter:
#   jupytext:
#     formats: py:percent
#     text_representation:
#       extension: .py
#       format_name: percent
#       format_version: '1.3'
#       jupytext_version: 1.16.7
#   kernelspec:
#     display_name: Python 3 (ipykernel)
#     language: python
#     name: python3
# ---

# %%
from dotenv.main import find_dotenv

2


# %%
def show_2d_model(model):
    obs = t.stack(t.meshgrid(t.linspace(0, 1, 100), t.linspace(0, 1, 100)), axis=-1).reshape(-1, 2)
    to_go = model(obs).reshape(100, 100)
    plt.matshow(to_go.data)
    plt.colorbar()


# %%
import torch as t
from torch.utils.data import TensorDataset, DataLoader, random_split
from ignite.engine import create_supervised_trainer, create_supervised_evaluator, Events
from ignite.handlers import ProgressBar
from ignite.metrics import Loss
import wandb
import os

dataset = TensorDataset(
    t.tensor(obs[:, :2], dtype=t.float), 
    t.tensor(to_go, dtype=t.float).reshape(-1, 1)
)
train_dataset, val_dataset = random_split(dataset, [int(0.8 * len(dataset)), len(dataset) - int(0.8 * len(dataset))])

model = t.nn.Sequential(networks.PositionEncoder(d=100), t.nn.Linear(100, 1))
trainer = create_supervised_trainer(model, t.optim.Adam(model.parameters(), lr=1e-3), t.nn.MSELoss())
evaluator = create_supervised_evaluator(model, metrics={'loss': Loss(t.nn.MSELoss())})

# wandb_logger = WandBLogger()
# trainer.add_event_handler(Events.EPOCH_COMPLETED, lambda _: wandb_logger.log(
#     {'val_loss': evaluator.run(DataLoader(val_dataset, batch_size=1024)).metrics['loss']},
#     trainer.state.iteration
# ))

ProgressBar().attach(trainer)
trainer.run(DataLoader(train_dataset, batch_size=1024, shuffle=True), max_epochs=1)
# wandb.finish()
