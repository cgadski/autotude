import matplotlib.pyplot as plt
import numpy as np
from tqdm import tqdm

import alti_rl as arl

r = 0
with arl.LostcityEnv() as env:
    for i in tqdm(range(30 * 60 * 10)):
        r += env.step()

print(f"Total reward: {r}")
