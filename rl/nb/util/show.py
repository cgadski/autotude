import numpy as np
from math import ceil, sqrt
import matplotlib.pyplot as plt
import torch as t
from typing import Optional, Iterable
from matplotlib.colors import TwoSlopeNorm
from matplotlib.axes import Axes


class RenderMode:
    def match(self, value: np.ndarray) -> bool:
        return False

    def render(self, value: np.ndarray, axes: Iterable[Axes]):
        pass


def matshow_colorful(ax, range: float, x):
    cmap = plt.get_cmap("PiYG")
    range = max(range, 1)
    norm = TwoSlopeNorm(vmin=-range, vcenter=0, vmax=range)
    return ax.matshow(x, cmap=cmap, norm=norm)


class Square(RenderMode):
    def match(self, value):
        return True

    def render(self, value, axes):
        b = value.shape[0]
        value = np.array(value.reshape((b, -1)))
        d = value.shape[1]
        square_dim = ceil(sqrt(d))
        range = np.max(np.abs(value))

        images = []
        for i, ax in enumerate(axes):
            square = np.zeros(square_dim**2)
            square[:d] = value[i]
            images.append(
                matshow_colorful(ax, range, square.reshape((square_dim, square_dim)))
            )


class Text(RenderMode):
    """
    Display a single number.
    """

    def match(self, value):
        return all(dim == 1 for dim in value.shape[1:])

    def render(self, value, axes):
        for i, ax in enumerate(axes):
            ax.text(0.5, 0.5, str(value[i].item()), ha="center", va="center")


class Vector(RenderMode):
    """
    Display as a row vector.
    """

    def match(self, value):
        s = value.shape
        return len(s) == 2 and s[-1] < 20

    def render(self, value, axes):
        range = np.max(np.abs(value))
        for i, ax in enumerate(axes):
            matshow_colorful(ax, range, value[i].reshape(1, -1))


class CirclePoints(RenderMode):
    """
    Display as points on the circle
    """

    def render(self, value, axes):
        import matplotlib.patches as patches

        for i, ax in enumerate(axes):
            circle = patches.Circle((0, 0), 1, fill=False)
            ax.add_artist(circle)

            points = value[i]
            ax.scatter(np.cos(points), np.sin(points), c="r", s=20)

            ax.set_xlim(-1.1, 1.1)
            ax.set_ylim(-1.1, 1.1)
            ax.set_aspect("equal", adjustable="box")


class SquarePoints(RenderMode):
    def match(self, value):
        return len(value.shape) >= 2 and value.shape[-1] == 2

    def render(self, value, axes):
        if len(value.shape) == 2:
            value = value[:, None, :]
        # value: (b, k, 2)

        for i, ax in enumerate(axes):
            points = value[i]  # (k, 2)
            ax.scatter(points[:, 0], points[:, 1], c="black", s=20)

            ax.add_patch(Rectangle((0, 0), 1, 1, fill=False, color="black"))
            ax.set_xlim(-0.1, 1.1)
            ax.set_ylim(-0.1, 1.1)
            ax.set_aspect("equal", adjustable="box")


class CircleVector(RenderMode):
    def render(self, value, axes):
        if len(value.shape) == 2:
            value = value[:, None, :]

        b, n_rows, n_cols = value.shape

        cmap = plt.get_cmap("PiYG")
        max_abs = np.max(np.abs(value))
        norm = TwoSlopeNorm(vmin=-max_abs, vcenter=0, vmax=max_abs)

        for i, ax in enumerate(axes):
            rad_range = np.linspace(0.5, 1, n_rows + 1)
            angle_range = np.linspace(0, 2 * np.pi, n_cols + 1)

            x = rad_range[:, None] * np.cos(angle_range)
            y = rad_range[:, None] * np.sin(angle_range)

            p = ax.pcolormesh(x, y, value[i], cmap=cmap, norm=norm)
            p.set_edgecolor("face")

            ax.set_xlim(-1.1, 1.1)
            ax.set_ylim(-1.1, 1.1)
            ax.set_aspect("equal", adjustable="box")


from matplotlib.patches import Rectangle


class SparseMatrix(RenderMode):
    def match(self, value):
        return len(value.shape) == 2

    def render(self, value, axes):
        for i, ax in enumerate(axes):
            b = value.shape[0]
            value = np.array(value.reshape((b, -1)))
            d = value.shape[1]
            square_dim = ceil(sqrt(d))

            for i, ax in enumerate(axes):
                square = np.zeros(square_dim**2)
                square[:d] = value[i]
                square = square.reshape((square_dim, square_dim))
                nonzero = np.where(square != 0)
                ax.scatter(nonzero[1], nonzero[0], c="black", s=20)
                ax.set_xlim(-0.5, square_dim - 0.5)
                ax.set_ylim(square_dim - 0.5, -0.5)
                ax.set_aspect("equal", adjustable="box")
                ax.add_patch(
                    Rectangle(
                        (-0.5, -0.5), square_dim, square_dim, fill=False, color="black"
                    )
                )


class DataRow:
    @staticmethod
    def from_array(x) -> Optional[np.ndarray]:
        if t.is_tensor(x):
            return x.detach().cpu().float().numpy()
        if isinstance(x, np.ndarray):
            return np.array(x, dtype=float)
        if isinstance(x, (bool, float, int)):
            return np.array([x], dtype=float)

    @staticmethod
    def from_list(x) -> Optional[np.ndarray]:
        if hasattr(x, "__iter__"):
            columns = [DataRow.from_array(e) for e in x]
            if all(x is not None for x in columns):
                return np.stack(columns, axis=0)  # pyright: ignore

    def __init__(self, data):
        self.rule: Optional[RenderMode] = None
        if isinstance(data, tuple) and (
            isinstance(data[0], RenderMode) or data[0] is None
        ):
            self.rule = data[0]
            data = data[1]

        try:
            arr = next(
                d
                for d in [DataRow.from_array(data), DataRow.from_list(data)]
                if d is not None
            )
        except StopIteration:
            print(data)
            raise Exception(f"Could not read array of type {type(data)}")
        self.arr: np.ndarray = arr
        self.shape = arr.shape

    def draw(self, axes):
        if self.rule is not None:
            self.rule.render(self.arr, axes)
            return

        for rule in [
            Vector(),
            Square(),
        ]:
            if rule.match(self.arr):
                rule.render(self.arr, axes)
                return


def split_dict_rows(d: dict[str, DataRow], max_cols: int) -> dict[str, DataRow]:
    new_d = {}
    for k, row in d.items():
        if row.shape[0] <= max_cols:
            new_d[k] = row
        else:
            for i in range(0, row.shape[0], max_cols):
                chunk = row.arr[i : i + max_cols]
                new_d[f"{k}_{i//max_cols}"] = DataRow((row.rule, chunk))
    return new_d


def show(*args, _max_cols: int = 8, _size: float = 1, **kwargs):
    d = {str(i): DataRow(arg) for i, arg in enumerate(args)}
    d.update({k: DataRow(v) for k, v in kwargs.items()})
    d = split_dict_rows(d, _max_cols)

    keys = list(d.keys())
    values = list(d.values())
    n_rows = len(d)
    max_cols = max(v.shape[0] for v in values)

    fig, axes = plt.subplots(
        n_rows,
        max_cols + 1,  # +1 for labels
        gridspec_kw={"width_ratios": [0.2] + [1] * max_cols},
        figsize=(_size * (max_cols + 1) * 2, _size * n_rows * 2),
    )

    if n_rows == 1:
        axes = [axes]

    for i, (row_name, row) in enumerate(zip(keys, values)):
        axes[i][0].text(0.5, 0.5, row_name, ha="center", va="center")
        row_axes = axes[i][1 : row.shape[0] + 1]
        row.draw(row_axes)
        for ax in axes[i]:
            ax.set_axis_off()

    plt.tight_layout()
    plt.show()
