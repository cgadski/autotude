.PHONY: copy_gen copy_polys upload recordings/

all: java_gen/ out/polys site_gen/

clean:
	rm -rf java_gen/ # java source gen
	rm -rf tools/ # CLI tools
	rm -rf hx_src/autotude/proto/ # haxe source gen
	rm -rf site_gen/ # static files for recording viewer

# protobuf sourcegen

PROTO_SRC=proto/
PROTO_FILES=$(wildcard $(PROTO_SRC)*)

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
rl/bot_driver/proto/: $(PROTO_FILES)
	mkdir -p $@
	protoc -I=$(PROTO_SRC) --python_out=$@ --mypy_out=$@ $^

# Haxe tools

TOOL_SRC = hx_src/autotude/proto/ $(wildcard hx_src/autotude/**)

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
bin/index: rust_src/bin/* rust_src/src/** rust_src/Cargo.toml
	mkdir -p $(@D)
	cd rust_src && cargo build --release --bin index
	cp rust_src/target/release/index $@

# Recording viewer

## js source for viewer
hx_src/out/viewer.js: hx_src/autotude/proto/ hx_src/build_viewer.hxml \
	$(wildcard hx_src/autotude/**) \
	$(wildcard hx_src/autotude/viewer/**) \
	data/polys
	mkdir -p $(@D)
	haxe hx_src/build_viewer.hxml
