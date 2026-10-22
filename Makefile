.DELETE_ON_ERROR:

all: copy_assets

clean:
	rm -rf bin/
	rm -rf java_gen/ # java source gen
	rm -rf viewer/autotude/proto/ # haxe source gen
	rm -rf rl/alti_rl/proto/ # python source gen
	rm -rf stats_db/proto/ # proto files for stats_db service docker build
	rm -rf viewer/out/

# protobuf stuff

PROTO_SRC = proto/
PROTO_FILES = $(wildcard $(PROTO_SRC)*)
.PHONY: gen_protobuf

gen_protobuf: java_gen/ viewer/autotude/proto/ rl/alti_rl/proto/

## java protobuf souregen
java_gen/: $(PROTO_FILES)
	mkdir -p $@
	protoc -I=$(PROTO_SRC) --java_out=$@ $^

## haxe protobuf sourcegen
viewer/autotude/proto/: $(PROTO_FILES)
	haxelib run protohx generate viewer/protohx.json
	bash viewer/clean_hxproto.sh

## python protobuf sourcegen
rl/alti_rl/proto/: $(PROTO_FILES)
	rm -rf $@
	mkdir -p $@
	cd rl; uv sync
	echo "running protoc..."
	@PATH=$(PATH):rl/lib/.venv/bin/ \
	   protoc -I=$(PROTO_SRC) --python_out=$@ --mypy_out=$@ $^
	find $@ -name "*.py*" -exec \
	   sed -i 's/^import \([a-zA-Z0-9_]*_pb2\) as/from . import \1 as/g' {} \;

# rust tools
bin/dump bin/cat-replay bin/index: stats_db/bin/* stats_db/src/** stats_db/Cargo.toml \
	stats_db/proto/
	mkdir -p $(@D)
	cd stats_db && cargo build --release --bin dump --bin index --bin cat-replay
	cp stats_db/target/release/{dump,index,cat-replay} bin/

# replay viewer
viewer/out/viewer.js: viewer/autotude/proto/ viewer/build_viewer.hxml \
	$(wildcard viewer/autotude/**) \
	$(wildcard viewer/autotude/viewer/**)
	mkdir -p $(@D)
	haxe viewer/build_viewer.hxml

# game resources
.PHONY: game_resources

game_resources:
	# uses ALTI_INSTALL and ALTI_MAP_PATH
	rm -rf game_resources/out/
	cd $@ && cargo build --release
	cd $@ && ./target/release/maps --map-list ladder_maps.csv out/maps
	cd $@ && ./target/release/sprites out/

.PHONY: copy_assets

# copying files to Docker build directories
copy_assets: altistats.com/nginx/assets/ \
	stats_db/proto/

# protobuf files for rust
stats_db/proto/: $(PROTO_FILES)
	rm -rf $@
	mkdir -p $@
	cp $(PROTO_SRC)/* $@

# js/html for nginx container
altistats.com/nginx/assets/: viewer/out/viewer.js viewer/viewer.html
	rm -rf $@
	mkdir -p $@
	cp viewer/out/viewer.js $@
	cp viewer/viewer.html $@/index.html
