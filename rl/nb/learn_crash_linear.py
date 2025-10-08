from sklearn.linear_model import SGDRegressor
from sklearn.ensemble import RandomForestRegressor
from sklearn.neural_network import MLPRegressor
import torch as t
from dataclasses import dataclass
from alti_rl.networks import PlaneEncoderDumb, NetOptions, crash_to_go, plane_features, DTYPE, sparse_pos
from simple_parsing import parse

@dataclass
class Options:
    pass

    def net_options(self):
        return NetOptions(
            d_embed=128
        )

def get_data():
    data = t.load("data/channelpark.pt")
    idx = t.arange(data["ob"].shape[0])
    mask = (idx > 2) & (idx < 5 * 60 * 30)
    return data["ob"][mask], crash_to_go(data["reward"][mask])

def go(opts: Options):
    x, y = t. get_data()
    mu = y.mean()
    print("variance: " + str(((mu - y) ** 2).mean()))

    # encoded = sparse_pos(plane_features(x).data, 80) # t d
    encoded = plane_features(x).data[:, :2]

    model = RandomForestRegressor()
    # model = MLPRegressor(hidden_layer_sizes=(100,))
    # model = SGDRegressor()
    print("fitting")
    model.fit(encoded, y)

    predicted = model.predict(encoded)
    print("res variance: " + str(((predicted - y.numpy()) ** 2).mean()))

if __name__ == "__main__":
    opts = parse(Options)
    go(opts)
