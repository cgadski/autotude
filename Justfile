set dotenv-load

ALTI_PATH := "../altitude/"
SERVER_DIST := ALTI_PATH + "BotServer/build/distributions/BotServer-1.1.9-SNAPSHOT.tar"
CLIENT_DIST := ALTI_PATH + "BotClient/build/distributions/BotClient-1.1.9-SNAPSHOT.tar"

default:
    just --list

# format everything
fmt:
    cd rust_src && cargo fmt
    hx-fmt --source hx_src/ > /dev/null

rust-build:
    cd rust_src && cargo build --release

index:
    cd rust_src \
    && cargo run --release --bin alti-index -- $ALTI_RECORDINGS

# haxe stuff

haxe-fmt:

# java stuff

extract-client:
    rm -rf game/client game/client.tar
    cp {{CLIENT_DIST}} game/client.tar
    cd game && tar -xf client.tar
    mv game/BotClient-1.1.9-SNAPSHOT game/client

extract-server:
    rm -rf game/server game/server.tar
    cp {{SERVER_DIST}} game/server.tar
    cd game && tar -xf server.tar
    mv game/BotServer-1.1.9-SNAPSHOT game/server

client: extract-client
    game/client/bin/BotClient

# site stuff

upload-replays:
	source ./indexer.sh
	cp site_src/viewer.html site_gen/viewer.html
	rm -rf site_gen/recordings
	mkdir -p site_gen/recordings
	python3 site_src/make_index.py
	rsync --progress -az site_gen/* root@cgad.ski:/www/alti_viewer/
