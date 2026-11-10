#!/usr/bin/env bash
# Compile the bot classes in rl/bots/ and run the bot server with them first
# on the classpath.
#
#   ./run.sh                    compile + run with ./config.xml
#   SERVER_CONFIG=/path/cfg.xml ./run.sh     use another config
#   RL_DIST=/path/to/lib        use another BotServer distribution lib dir
set -euo pipefail

RL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${RL_DIST:-$(echo "$RL_DIR"/../java_dist/BotServer-*/lib)}"

mkdir -p "$RL_DIR/classes"
CP="$RL_DIR/classes:$(printf '%s:' "$LIB_DIR"/*.jar)"

echo "[rl] compiling rl/bots/*.java"
javac -encoding UTF-8 -cp "$CP" -d "$RL_DIR/classes" "$RL_DIR"/bots/*.java

export ALTI_HOME="${ALTI_HOME:-$RL_DIR/../alti_home}"
export SERVER_CONFIG="${SERVER_CONFIG:-$RL_DIR/config.xml}"
export SERVER_RUNTIME="${SERVER_RUNTIME:-$RL_DIR/runtime}"
mkdir -p "$SERVER_RUNTIME"

echo "[rl] running bot server with $SERVER_CONFIG"
exec java -cp "$CP" botserver.Main
