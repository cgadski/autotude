from .proto.command_pb2 import Cmd
from .controller import Controller
from time import sleep
from tqdm import tqdm

def main():
    pass
    # controller = Controller()

    # cmd = Cmd()
    # controller.update(cmd)
    # print(f"Tick {update.time}: {len(update.objects)} objects", end="")
    # print()

if __name__ == "__main__":
    with Controller("simple_ffa") as c:
        cmd = Cmd()
        cmd.inputs[0].controls = 1
        for _ in tqdm(range(1000)):
            c.update(cmd)
