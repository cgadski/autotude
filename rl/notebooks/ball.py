# %%
import numpy as np
import matplotlib.pyplot as plt

data = np.load("/Users/cgadski/dev/autotude/rust_src/ball_data.npz")
data


# %%
(data["is_pro"] == 1).mean()


# %%
def modern_art_thing(data):
    status = data["ball_active"]
    pos = np.stack([data["ball_pos_x"], data["ball_pos_y"]], axis=-1)
    mask = np.zeros_like(status) == 0 # status == 0
    pos = pos[mask]
    status = status[mask]

    N_STEPS = None # 30 * 60 * 60
    fig, ax = plt.subplots()
    fig.set_figwidth(16)
    fig.set_figheight(8)
    ax.set_aspect(1)
    plt.scatter(pos[:N_STEPS, 0], pos[:N_STEPS, 1], s=1, alpha=0.02, c = status[:N_STEPS] > 0)

modern_art_thing(data)
# %%
def modern_art_thing(data):
    status = data["ball_active"]
    pos = np.stack([data["ball_pos_x"], data["ball_pos_y"]], axis=-1)
    mask = np.zeros_like(status) == 0 # status == 0
    pos = pos[mask]
    status = status[mask]

    N_STEPS = None # 30 * 60 * 60
    fig, ax = plt.subplots()
    fig.set_figwidth(16)
    fig.set_figheight(8)
    ax.set_aspect(1)
    plt.scatter(pos[:N_STEPS, 0], pos[:N_STEPS, 1], s=1, alpha=0.02, c = status[:N_STEPS] > 0)


# %%
from scipy.stats import gaussian_kde

def kde_movement(data):
    status = data["ball_active"]
    pos = np.stack([data["ball_pos_x"], data["ball_pos_y"]], axis=-1)

    mask = status == 3
    pos = pos[mask]
    status = status[mask]

    kernel = gaussian_kde(pos.T)
    x, y = np.mgrid[0:5000:25, 0:2000:25]
    estimates = kernel(np.stack([x.flatten(), y.flatten()]))
    plt.matshow(estimates.reshape(x.shape).T[::-1, :])

kde_movement(data)
# %%
