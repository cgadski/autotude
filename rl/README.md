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

## Next steps

At the moment, we can train a Q function network in the way described above, and then run the greedy poliy (choosing an action with highest value) online with `alti_rl.online_client`. I found that this bot succeeds pretty well at avoiding crashing on `ffa_cave`.

The next things that I think would make sense are:

(1) Generate position dependent-features that tell us about the geometry of the map. The first things that come to mind are just clear distances to the nearest obstacles. I'm not sure about the best way to produce this data; we could either generate it once (say with a rust program, as in `/game_resources/`) and store arrays of numbers to be interpolated, or compute clear distances on the fly from the map poly data, or do something in between (pre-process in some way). I don't want running the bots to be very expensive in memory, and of course generating these features needs to be as fast as possible for training.
(2) Using the position-dependent features, train a predictive model for the plane dynamics and for the incidence of damage. This would be a good way to validate our position features. I'm curious how accurate the predictive model can be. At least as a first step, I think we could treat crashing as the end of a trajectory, so we don't have to model the collision physics.
(3) Ideally, the predictive model would run faster than the bot server. Using this model, we could come up with a deep Q learning pipeline that lets us learn a Q function for navigating to an arbitrary waypoint on an arbitrary map.

In reinforcement learning I think it's easy for things to go off the rails if we are making some mistake in our features/exploration policy/hyperparameters/architecture. Accomplishing (3) would validate that we're on the right track. I also think that having a predictive model would come in handy to speed up training. After (3) is working we could move to more usual methods like soft actor-critic.
