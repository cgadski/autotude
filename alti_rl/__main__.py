from alti_rl.proto.command_pb2 import Cmd
from alti_rl.controller import Controller

def main(controller:Controller):
    controller = Controller()

    cmd = Cmd()
    cmd.setMap.map = "tbd_asteroids"
    print(f"Setting map: {cmd.setMap.map}")
    controller.send_command(cmd)
    controller.read_update()

    cmd = Cmd()
    while True:
        update = controller.read_update()
        controller.send_command(cmd)
        print(f"Tick {update.time}: {len(update.objects)} objects", end="")
        print()

if __name__ == "__main__":
    with Controller() as controller:
        main(controller)
