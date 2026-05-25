import numpy as np
from scipy.stats import binomtest

from .games import get_team_outcomes

teams, outcomes = get_team_outcomes()
ct = np.bincount(outcomes)
test = binomtest(ct[0], ct[0] + ct[1])
print(test)
print(test.proportion_ci(confidence_level=0.99))
