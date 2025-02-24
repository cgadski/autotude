.DELETE_ON_ERROR:

.PHONY: copy_gen copy_polys upload recordings/

all: java_gen/ out/polys site_gen/

clean:
	rm -rf java_gen/ # java source gen
	rm -rf hx_src/autotude/proto/ # haxe source gen

# protobuf sourcegen

PROTO_SRC = proto/
PROTO_FILES = $(wildcard $(PROTO_SRC)*)

## java sourcegen
java_gen/: $(PROTO_FILES)
	mkdir -p $@
	protoc -I=$(PROTO_SRC) --java_out=$@ $^
	rm java_gen/PolyOuterClass.java

## haxe sourcegen
hx_src/autotude/proto/: $(PROTO_FILES)
	haxelib run protohx generate hx_src/protohx.json
	bash hx_src/clean_hxproto.sh

## python sourcegen
alti_rl/proto/: $(PROTO_FILES)
	rm -rf $@
	mkdir -p $@
	protoc -I=$(PROTO_SRC) --python_out=$@ --mypy_out=$@ $^

# Haxe tools

TOOL_SRC = $(wildcard hx_src/autotude/**)

bin/write_polys.n: $(TOOL_SRC) ; haxe hx_src/build_tools.hxml

# Polys
data/polys: bin/write_polys.n poly_src/
	mkdir -p $(@D)
	neko ./bin/write_polys.n
	gzip $@
	mv $@.gz $@
	@echo "Size of poly file (bytes): "
	@wc -c $@

## indexer
bin/index bin/index-lite: rust_src/bin/* rust_src/src/** rust_src/Cargo.toml
	mkdir -p $(@D)
	cd rust_src && cargo build --release --bin index --bin index-lite
	cp rust_src/target/release/index{,-lite} bin/

# Recording viewer

## js source for viewer
hx_src/out/viewer.js: hx_src/autotude/proto/ hx_src/build_viewer.hxml \
	$(wildcard hx_src/autotude/**) \
	$(wildcard hx_src/autotude/viewer/**) \
	data/polys
	mkdir -p $(@D)
	haxe hx_src/build_viewer.hxml

.PHONY: docker_cp

docker_cp: altistats.com/nginx/assets/ \
	rust_src/proto/

rust_src/proto/: $(PROTO_FILES)
	rm -rf $@
	mkdir -p $@
	cp $(PROTO_SRC)/* $@

altistats.com/nginx/assets/: hx_src/out/viewer.js viewer/templates/viewer.html
	rm -rf $@
	mkdir -p $@
	cp hx_src/out/viewer.js $@
	cp viewer/templates/viewer.html $@/index.html
