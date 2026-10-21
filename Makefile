.DELETE_ON_ERROR:

all: copy_assets

clean:
	rm -rf bin/
	rm -rf java_gen/ # java source gen
	rm -rf hx_src/autotude/proto/ # haxe source gen
	rm -rf stats_db/proto/ # copies proto files

PROTO_SRC = proto/
PROTO_FILES = $(wildcard $(PROTO_SRC)*)

# java sourcegen
java_gen/: $(PROTO_FILES)
	mkdir -p $@
	protoc -I=$(PROTO_SRC) --java_out=$@ $^

# haxe sourcegen
hx_src/autotude/proto/: $(PROTO_FILES)
	haxelib run protohx generate hx_src/protohx.json
	bash hx_src/clean_hxproto.sh


# python sourcegen
rl/altitude_rl/proto/: $(PROTO_FILES)
	rm -rf $@
	mkdir -p $@
	cd rl; uv sync
	echo "running protoc..."
	@PATH=$(PATH):rl/lib/.venv/bin/ \
	   protoc -I=$(PROTO_SRC) --python_out=$@ --mypy_out=$@ $^
	find $@ -name "*.py*" -exec \
	   sed -i 's/^import \([a-zA-Z0-9_]*_pb2\) as/from . import \1 as/g' {} \;

TOOL_SRC = $(wildcard hx_src/autotude/**)

bin/replay_tool.n: $(TOOL_SRC) hx_src/autotude/proto/
	haxe hx_src/build_tools.hxml

# indexer
bin/dump bin/cat-replay bin/index-lite: stats_db/bin/* stats_db/src/** stats_db/Cargo.toml \
	stats_db/proto/
	mkdir -p $(@D)
	cd stats_db && cargo build --release --bin dump --bin index-lite --bin cat-replay
	cp stats_db/target/release/{dump,index-lite,cat-replay} bin/

# js source for viewer
hx_src/out/viewer.js: hx_src/autotude/proto/ hx_src/build_viewer.hxml \
	$(wildcard hx_src/autotude/**) \
	$(wildcard hx_src/autotude/viewer/**)
	mkdir -p $(@D)
	haxe hx_src/build_viewer.hxml

# everything the viewer loads from the game: map artwork (from alti_home/maps,
# maps the game client downloaded and $ALTI_MAP_DIRS), and sprites, effects
# and sounds (from an Altitude install at $ALTI_INSTALL)
GAME_RESOURCES_SRC = game_resources/Cargo.toml $(wildcard game_resources/src/*) $(wildcard game_resources/bin/*)

game_resources/out/: $(GAME_RESOURCES_SRC) $(wildcard alti_home/maps/*.altx)
	if [ -z "$(ALTI_INSTALL)" ]; then \
		echo "ALTI_INSTALL not set"; \
		exit 1; \
	fi
	cd game_resources && cargo build --release
	game_resources/target/release/maps $@maps
	game_resources/target/release/sprites "$(ALTI_INSTALL)" $@

# the viewer looks for them in game_resources/ next to its page
hx_src/out/game_resources/: game_resources/out/
	rm -rf $@
	cp -r game_resources/out $@

.PHONY: copy_assets

# copy assets required to build sub-projects
copy_assets: altistats.com/nginx/assets/ \
	stats_db/proto/

# proto files for rust
stats_db/proto/: $(PROTO_FILES)
	rm -rf $@
	mkdir -p $@
	cp $(PROTO_SRC)/* $@

# js/html of viewer for altistats.com
altistats.com/nginx/assets/: hx_src/out/viewer.js hx_src/viewer.html \
	hx_src/out/game_resources/
	rm -rf $@
	mkdir -p $@
	cp hx_src/out/viewer.js $@
	cp hx_src/viewer.html $@/index.html
	cp -r hx_src/out/game_resources $@
