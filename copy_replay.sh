#!/bin/bash

RECORDING_PATH="$HOME/Library/Application Support/NimblyGames/altitude/recordings/"

NEWEST=$(ls -t "$RECORDING_PATH" | head -n 1)
cp "$RECORDING_PATH"/$NEWEST example_recordings/$1.pb.gz

