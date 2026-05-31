import argparse

import matplotlib.colors as colors
import matplotlib.pyplot as plt
import torch


def show_density(data):
    plane = data["plane"][data["mask"]]
    max = plane[:, :2].max(dim=0).values
    fig, ax = plt.subplots(figsize=(10, 4))
    h = ax.hist2d(
        plane[:, 0],
        plane[:, 1],
        bins=[100, 50],
        range=[[0, max[0]], [0, max[1]]],
        cmap="plasma",
        norm=colors.LogNorm(),
    )
    fig.colorbar(h[3], ax=ax, label="count")
    ax.set_xlabel("x")
    ax.set_ylabel("y")
    ax.set_aspect("equal")
    plt.tight_layout()
    plt.show()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("path", type=str, help="path to the data file")
    args = parser.parse_args()
    data = torch.load(args.path)
    show_density(data)
