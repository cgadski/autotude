import altitude_rl as arl
import numpy as np
from altitude_rl.online_client import OnlineClient
import os

def wrap_180(angle):
    return (angle + 180) % 360 - 180

def make_config():
    pw = os.environ["ALTI_PW"]
    config = arl.ClientConfig(
        user="me@cgad.ski",
        pw=pw,
        server="Official #4 - FFA+TBD+Ball - maxPing=400"
    )
    config.set(port=27281)
    return config

class ControlledClient(OnlineClient):
    def __init__(self):
        super().__init__(make_config())
        self.last_angle = None
        self.cmd = arl.Cmd()

    def get_target(self, o):
        current = o.angle / 10
        options = current + np.arange(0, 360, 2)
        clears = np.array(o.clear_distances)
        costs = 1 / (clears ** 2 + 0.1) + 1e-8 * np.abs(wrap_180(options - current))
        return options[np.argmin(costs)]

    def control(self, o) -> int:
        if o is None:
            self.last_angle = None
            return 0

        if self.last_angle is None:
            self.last_angle = o.angle / 10
            return 0

        angle = o.angle / 10
        target_angle = self.get_target(o)
        prop = wrap_180(angle - target_angle)
        diff = angle - self.last_angle
        self.last_angle = angle

        pd_response = prop + 3 * diff
        TOL = 3
        controls = 0
        if pd_response > TOL:
            controls = 2
        elif pd_response < -TOL:
            controls = 1
        return controls + 16

    def on_update(self, update):
        my_plane = None
        for o in update.objects:
            if o.type < 5 and o.controllable:
                my_plane = o
                break

        cmd = arl.ClientCmd()
        cmd.input.controls = self.control(my_plane)
        return cmd

ControlledClient().poll()
