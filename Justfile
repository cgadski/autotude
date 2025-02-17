set dotenv-load

default:
    just --list

# Install dependencies through nix
nix:
	nix build -L -f . env -o etc/nix.env

# Upload to production
up:
    rsync --progress -av \
        --exclude 'recordings/' \
        alti_home/ \
        root@altistats.com:/root/autotude/alti_home/

# Set up alti_home/ using Altitude source tree at $ALTI_SRC
setup:
	if [ -z "$ALTI_SRC" ]; then \
		echo "ALTI_SRC not set"; \
		exit 1; \
	fi
	mkdir -p alti_home/
	tar -xf $ALTI_SRC/BotServer/build/distributions/*.tar -C alti_home/
	tar -xf $ALTI_SRC/BotClient/build/distributions/*.tar -C alti_home/
	ln -sf $PWD/alti_home/BotServer*/bin/BotServer bin/server
	ln -sf $PWD/alti_home/BotClient*/bin/BotClient bin/client
	rsync -ru \
		$ALTI_SRC/BotServer/build/alti_home/{maps,resources,data} \
		alti_home/

# Format haxe source
fmt-haxe:
	hx-fmt --source hx_src/

# Index replays at $ALTI_RECORDINGS into data/index.db
index:
    duckdb data/index.db < data/schema.sql
    index \
       --replays $ALTI_RECORDINGS \
       --out data/index.db \
       --progress

# Dump extended database of 4ball recordings into data/dump.db
dump-4ball:
    duckdb -csv -noheader data/index.db < data/4ball.sql > data/4ball.csv
    duckdb data/dump.db < data/schema.sql
    cat data/4ball.csv | index \
        --stdin \
        --out data/dump.db \
        --dump \
        --progress


JAVA_INSTALL := env_var_or_default("ALTI_SRC", "") + "/Altitude/src/main/java/em/altitude/game/protos/"

# Copy generated java source into Altitude tree
export-java-gen:
	if [ -z "$ALTI_SRC" ]; then \
		echo "ALTI_SRC not set"; \
		exit 1; \
	fi
	make java_gen/
	rm -rf {{JAVA_INSTALL}}
	mkdir -p {{JAVA_INSTALL}}
	cp java_gen/em/altitude/game/protos/* {{JAVA_INSTALL}}
