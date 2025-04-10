from datetime import time
import torch.utils.data as D
import altitude_rl as arl
import torch as t
from tqdm import tqdm
import wandb
import argparse
import numpy as np
from pprint import pprint
import matplotlib.pyplot as plt

d = 128
model = t.nn.Sequential(
    arl.networks.AngleEncoder(d=d),
    t.nn.Linear(d, d),
    t.nn.ReLU(),
    t.nn.Linear(d, 2),
    #t.nn.Flatten(start_dim=0),
).to(t.float32)

model.load_state_dict(t.load("data/model.pt", weights_only=True))

print("loaded model")


def to_torch(x):
    return t.tensor(x).float()

def show(obs):    
    
    plt.scatter(obs[:, 0], obs[:, 1], s=1)  
    plt.xlim(0, 1)  
    plt.ylim(0, 1) 
    plt.savefig("data/model_use.png", dpi=300)


SAMPLES = 1000

obs = t.zeros((SAMPLES, 2))
ob,dxdy =t.zeros(2)
estimate=t.zeros(2)
input=t.zeros(1)
for i in tqdm(range(SAMPLES)):
    ob= dxdy + ob
    obs[i]=dxdy + ob
    if i %100== 0:
       ob = t.rand(2) 
       obs[i]=ob
       input = t.rand(1)
    dxdy = model(input)
show(obs.detach().numpy())