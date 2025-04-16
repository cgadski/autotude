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
    arl.networks.MultiObsEncoder(d=d),
    t.nn.Linear(d, d),
    t.nn.ReLU(),
    t.nn.Linear(d, 3),
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



# init_obs = t.stack(
#     (t.linspace(0,1,100),
#      t.full((100,),0.5),
#      t.repeat_interleave(t.tensor([0.0,1800]),repeats=50)),
# dim=1)
init_obs = t.stack(
    (t.linspace(0,1,100),
     t.full((100,),0.5),
     t.repeat_interleave(t.tensor([0.0,1800]),repeats=50)),
dim=1)
obs = t.zeros((100*1030,3))
obs[0:30] = init_obs[0].repeat(30,1) 
ob = init_obs[-1]
out = init_obs[-1]
input = t.zeros((30,5))
for i in tqdm(range(100*1000)):
    obs[i+30] = out[:] 
    input[:-1,:3] = obs[-29:]
    if i%1000 == 0:
        input[-1,:3] = init_obs[i//1000]
    else:
        input[-1,:3] = out[0]
    input[:,3:] = t.zeros(2).repeat(30,1)
    out = model(input)
    print(out)
    
    
    
show(obs[:,:2].detach().numpy())