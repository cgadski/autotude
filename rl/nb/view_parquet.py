# %%
import polars
import matplotlib.pyplot as plt

df = polars.read_parquet("../data/data.parquet")
df

# %%
import numpy as np
df.write_csv("../data/ball.csv")
# np.isnan(df[:100].to_numpy())

# %%
t = 0 * 30
s = slice(t, t + 120 * 30)

fig, ax = plt.subplots()
for i in range(8):
    if i >= 4:
        c = "red"
    else:
        c = "blue"
    ax.plot(
        df[f"p{i}_x"][s],
        df[f"p{i}_y"][s],
        c=c,
        alpha=0.2
    )

ax.plot(df["ball_x"][s], df["ball_y"][s], c="black")

ax.set_aspect(1)


# %%

df["team"].value_counts()

# %%
