# %%
from pathlib import Path
import sqlite3
import pandas as pd
import numpy as np
from dataclasses import dataclass

pd.set_option('display.float_format', '{:.2f}'.format)

db_path = Path("../../stats_db/stats.db")

def query(query):
    with sqlite3.connect(db_path) as conn:
        return pd.read_sql_query(query, conn)

# %%
# all players with more than 100 games
known_players = query('''
    SELECT handle_key, handle
    FROM handles
    NATURAL JOIN players_short
    WHERE NOT automatic
    GROUP BY handle_key
    HAVING COUNT() >= 100
''')


# %%
def get_games():
    games = query('''
        SELECT
            dense_rank() OVER (ORDER BY replay_key) - 1 AS game_idx,
            row_number() OVER (PARTITION BY replay_key ORDER BY team, handle_key) - 1 AS handle_idx,
            handle_key,
            replay_key,
            team,
            won
        FROM players_short
        NATURAL JOIN ladder_games
    ''')
    n = int(games.shape[0] / 8)
    teams = np.zeros((n, 8), dtype=np.int16)
    teams[games["game_idx"], games["handle_idx"]] = games["handle_key"]
    outcomes = games["won"][8 * np.arange(n)].astype(np.int16).to_numpy()
    replays = games["replay_key"][8 * np.arange(n)].astype(np.int16).to_numpy()
    return teams, outcomes, replays

# %%
def vectorize_teams(teams):
    # teams: n 8 -> handle_key
    n = teams.shape[0]
    res = np.zeros((n, known_players.shape[0] + 1))  # n d

    handle_idx = {handle_key: i for i, handle_key in enumerate(known_players['handle_key'])}

    for i in range(n):
        for j in range(8):
            handle_key = teams[i, j]
            res[i, handle_idx.get(handle_key, -1)] -= 1 if j >= 4 else -1

    return res


# %%
from sklearn.linear_model import LogisticRegression
from sklearn.neighbors import KNeighborsClassifier
from sklearn.svm import SVC
from sklearn.metrics import log_loss
import matplotlib.pyplot as plt

teams, outcomes, replays = get_games()
x = vectorize_teams(teams)
all_known = np.abs(x[:, :-1]).sum(axis=1) == 8
x = x[all_known]
outcomes = outcomes[all_known]
all_known.sum()

# %%
outcomes.sum()

# %%
model = LogisticRegression(penalty='l2', solver='saga')
# model = SVC(kernel="poly", degree=2)
model.fit(x, outcomes)
((model.predict_proba(x)[:, 0] < 0.5) == outcomes).mean()


# %%
prob = model.predict_proba(x)[:, 0]
tau = np.linspace(0, 1, num=1000)
np.argmax(((prob < tau[:, None]) == outcomes).mean(axis=1))

# %%
bins = np.linspace(0, 1, num=15)
pred_df = pd.DataFrame({
    "pred": np.digitize(prob, bins),
    "outcome": outcomes
})
grouped = pred_df.groupby("pred").mean()
plt.scatter(bins[grouped.index], grouped)



# %%
replays[np.argmax(np.abs(logits[:, 0] - logits[:, 1]))]


# %%
rating_df = pd.DataFrame({
    "handle": known_players["handle"],
    "rating": model.coef_[0, :-1] / np.log(2)
}).sort_values("rating", ascending=False).reset_index(drop=True)

print(rating_df.to_string())
