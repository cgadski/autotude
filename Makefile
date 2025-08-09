.DELETE_ON_ERROR:

all: copy_assets

clean:
	rm -rf bin/
	rm -rf java_gen/ # java source gen
	rm -rf poly_src/
	rm -rf hx_src/autotude/proto/ # haxe source gen
	rm -rf stats_db/proto/ # copies proto files

PROTO_SRC = proto/
PROTO_FILES = $(wildcard $(PROTO_SRC)*)

# java sourcegen
java_gen/: $(PROTO_FILES)
	mkdir -p $@
	protoc -I=$(PROTO_SRC) --java_out=$@ $^
	rm java_gen/PolyOuterClass.java

# haxe sourcegen
hx_src/autotude/proto/: $(PROTO_FILES)
	haxelib run protohx generate hx_src/protohx.json
	bash hx_src/clean_hxproto.sh


# python sourcegen
rl/lib/altitude_rl/proto/: $(PROTO_FILES)
	rm -rf $@
	mkdir -p $@
	cd rl/lib; uv sync
	echo "running protoc..."
	@PATH=$(PATH):rl/lib/.venv/bin/ \
	   protoc -I=$(PROTO_SRC) --python_out=$@ --mypy_out=$@ $^
	find $@ -name "*.py*" -exec \
	   sed -i 's/^import \([a-zA-Z0-9_]*_pb2\) as/from . import \1 as/g' {} \;

TOOL_SRC = $(wildcard hx_src/autotude/**)

bin/write_polys.n: $(TOOL_SRC) hx_src/autotude/proto/
	haxe hx_src/build_tools.hxml

# polys
poly_src/:
	tar -xf poly_src.tar.gz

data/polys: bin/write_polys.n poly_src/
	mkdir -p $(@D)
	neko ./bin/write_polys.n
	gzip $@
	mv $@.gz $@
	@echo "Size of poly file (bytes): "
	@wc -c $@

# indexer
bin/dump bin/index-lite: stats_db/bin/* stats_db/src/** stats_db/Cargo.toml \
	stats_db/proto/
	mkdir -p $(@D)
	cd stats_db && cargo build --release --bin dump --bin index-lite
	cp stats_db/target/release/{dump,index-lite} bin/

# js source for viewer
hx_src/out/viewer.js: hx_src/autotude/proto/ hx_src/build_viewer.hxml \
	$(wildcard hx_src/autotude/**) \
	$(wildcard hx_src/autotude/viewer/**) \
	data/polys
	mkdir -p $(@D)
	haxe hx_src/build_viewer.hxml

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
altistats.com/nginx/assets/: hx_src/out/viewer.js hx_src/viewer.html
	rm -rf $@
	mkdir -p $@
	cp hx_src/out/viewer.js $@
	cp hx_src/viewer.html $@/index.html
