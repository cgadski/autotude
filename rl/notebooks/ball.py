# %%
import numpy as np
import matplotlib.pyplot as plt

data = np.load("/Users/cgadski/dev/autotude/rust_src/ball_data.npz")
data


# %%
# (data["is_pro"] == 1).sum() / (30 * 60)
data["ball_pos_x"][data["ball_active"] >= 0].mean()

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
def just_pro(data):
    fig, ax = plt.subplots()
    fig.set_figwidth(16)
    fig.set_figheight(8)
    ax.set_aspect(1)

    status = data["ball_active"]
    pos = np.stack([data["ball_pos_x"], data["ball_pos_y"]], axis=-1)
    plt.scatter(pos[:, 0], pos[:, 1], s=1, alpha=0.5)

    START = 30 * 60 * 60
    END = START + 30 * 60 * 15
    mask = data["is_pro"] == 0
    pos = pos[mask]
    status = status[mask]
    is_right = status == 4
    pos[is_right, 0] = 2581 + 2581 - pos[is_right, 0]

    plt.scatter(pos[START:END, 0], pos[START:END, 1], s=1, alpha=0.5)

just_pro(data)

# %%
from scipy.stats import gaussian_kde

# %%
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
def kde_movement_pro(data):
    status = data["ball_active"]
    pos = np.stack([data["ball_pos_x"], data["ball_pos_y"]], axis=-1)

    mask = data["is_pro"] == 1
    pos = pos[mask]
    status = status[mask]

    is_right = status == 4
    pos[is_right, 0] = 2581 + 2581 - pos[is_right, 0]

    kernel = gaussian_kde(pos.T)
    x, y = np.mgrid[0:5000:25, 0:2000:25]
    estimates = kernel(np.stack([x.flatten(), y.flatten()]))
    plt.matshow(estimates.reshape(x.shape).T[::-1, :])

kde_movement_pro(data)
