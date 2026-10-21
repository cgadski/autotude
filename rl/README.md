## Learning to navigate

`alti_rl.fly_solo`, when run without being passed a model, runs the "random turning" policy on `ffa_cave`. This crashes into walls very frequently! As a first objective, I want to make bots that can efficiently navigate to different parts of `ffa_cave` without crashing.

`uv run -m alti_rl.fly_solo --hours 200 --out data/flying.pt` runs in about 20 minutes and generates 200 hours of random flying. During this period, the bot succeeds in getting to every region of the map, and does some things that I didn't know were possible (clipping through walls without dying!). This data is structured as a dict of pytorch arrays. The available attributes are the ones defined in `get_solo_obs` in `simple_environments.py`. Basically these are direct copies of the important fields from the protobuf schema:

`alive`, `x`, `y`, `angle`, `stalled`, `throttle`, `ammo`, `damage`, `controls`

`controls` is a bit mask, as documented in `game_object.proto`.

Now let's do some off-policy RL. As a first step, we'll just learn the Q function describing time until forced crash. Our Bellman relations are $Q(s, a) = 0$ for a pair $(s, a)$ that result in a crash, and  $Q(s, a) = (1 - \gamma) + \gamma * \max_{a'} Q({s'}, {a'})$ otherwise. So, $Q \approx 1$ for survivable states, and $Q < 1$ when a crash is inevitable.

The pipeline is:

- `alti_rl.data.encode_plane_state` normalizes some features of the plane and a boolean mask filtering out deaths / respawns and other one-off situations where it doesn't make sense to learn anything from the data. These features don't include absolute position information.
- Then, `alti_rl.networks` defines a module dedicated to taking un-normalized positions to "position embeddings". Position embeddings might tell us something about the map geometry (clear distances, etc.) This can be learned per-map. Eventually it may be a good idea to manually define some features as a function of the map geometry. For now I'm curious whether these embeddings can be learned.
- Then, a small MLP goes from here to a vector-valued output, and `learn_crash` applies a sigmoid and trains this to be a Q function.
