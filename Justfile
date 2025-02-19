set dotenv-load

default:
    just --list

# Install dependencies through nix
nix:
	nix build -L -f . env -o etc/nix.env

# Set up alti_home/ using Altitude source tree at $ALTI_SRC
setup:
	if [ -z "$ALTI_SRC" ]; then \
		echo "ALTI_SRC not set"; \
		exit 1; \
	fi
	mkdir -p java_dist/
	tar -xf $ALTI_SRC/BotServer/build/distributions/*.tar -C java_dist/
	tar -xf $ALTI_SRC/BotClient/build/distributions/*.tar -C java_dist/
	ln -sf $PWD/java_dist/BotServer*/bin/BotServer bin/server
	ln -sf $PWD/java_dist/BotClient*/bin/BotClient bin/client
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

# Docker

push-client:
	docker build -t magneticduck/botclient:latest -f docker/botclient.Dockerfile .
	docker push magneticduck/botclient

# Deployment

# Download recordings
dl:
	rsync --progress -av root@altistats.com:/root/alti_home/recordings/ ./alti_home/recordings/

# Deploy altistats.com with docker compose
deploy:
	rsync --progress -av \
		--exclude 'recordings/' \
		./alti_home/ \
		root@altistats.com:/root/alti_home/
	docker --host "ssh://root@altistats.com" \
		compose -f docker/altistats.yml up -d --remove-orphans --build

dev:
	docker context use default
	docker compose -f docker/dev.yml up --remove-orphans --build

pg:
	psql -h altistats.com -d altistats -U root

update-schema:
	cat sql_schema/{listings,index}.sql \
		| psqldef altistats -U root -h=altistats.com
