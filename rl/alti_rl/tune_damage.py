"""Optuna hyperparameter search for NavNet damage prediction."""

import argparse

import optuna
import torch

from alti_rl.learn_damage import prepare, run
from alti_rl.networks import Options


def objective(trial: optuna.Trial, plane, dmg_value, act_index) -> float:
    lr = trial.suggest_float("lr", 1e-4, 1e-1, log=True)
    opts = Options(
        d_embed=512,
        n_layers=3,
        lr=lr,
        beta1=trial.suggest_float("beta1", 0.5, 0.99),
        beta2=trial.suggest_float("beta2", 0.9, 0.9999),
        epochs=1,
        lr_min=trial.suggest_float("lr_min", 0.0, lr),
        activation=trial.suggest_categorical(
            "activation", ["relu", "tanh", "silu", "gelu"]
        ),
        batch_size=512,
    )
    return run(opts, plane, dmg_value, act_index)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("data_path")
    parser.add_argument("--trials", type=int, default=100)
    parser.add_argument("--study", type=str, default="tune_damage")
    parser.add_argument("--storage", type=str, default="sqlite:///optuna.db")
    args = parser.parse_args()

    data = torch.load(args.data_path, weights_only=False)
    plane, dmg_value, act_index = prepare(data, Options())

    study = optuna.create_study(
        study_name=args.study,
        direction="minimize",
        storage=args.storage,
        load_if_exists=True,
    )
    study.optimize(
        lambda trial: objective(trial, plane, dmg_value, act_index),
        n_trials=args.trials,
    )

    print("\nBest trial:")
    print(f"  value: {study.best_value:.4f}")
    print(f"  params: {study.best_params}")
