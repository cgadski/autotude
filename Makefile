.PHONY: copy_gen copy_polys upload recordings/

all: java_gen/ out/polys site_gen/

clean:
	rm -rf java_gen/ # java source gen
	rm -rf out/ # polys
	rm -rf tools/ # CLI tools
	rm -rf indexer/ # replay indexer
	rm -rf hx_src/autotude/proto/ # haxe source gen
	rm -rf site_gen/ # static files for recording viewer
	rm -rf site_src/index.csv

ALTI_PATH=../altitude/
GEN_INSTALL_PATH=$(ALTI_PATH)Altitude/src/main/java/em/altitude/game/protos/
PROTO_SRC=proto/
PROTO_FILES=$(wildcard proto/*)

# protobuf stuff

## generated java classes

java_gen/: $(PROTO_FILES)
	mkdir -p $@
	protoc -I=$(PROTO_SRC) --java_out=$@ $^
	rm java_gen/PolyOuterClass.java

## copy generated classes to altitude source
copy_gen: java_gen/
	rm -rf $(GEN_INSTALL_PATH)
	mkdir -p $(GEN_INSTALL_PATH)
	cp java_gen/em/altitude/game/protos/* $(GEN_INSTALL_PATH)

## generated haxe classes
hx_src/autotude/proto/: $(PROTO_FILES)
	haxelib run protohx generate protohx.json
	bash clean_hxproto.sh

# Haxe tools

TOOL_SRC = hx_src/autotude/proto/ $(wildcard hx_src/autotude/**)

tools/: $(TOOL_SRC) ; haxe build_tools.hxml

indexer/: $(TOOL_SRC) ; haxe build_indexer.hxml

# Polys
out/polys: tools/ poly_src/
	mkdir -p out/
	neko ./tools/write_polys.n
	gzip $@
	mv $@.gz $@
	@echo "Size of poly file (bytes): "
	@wc -c $@

# Recording viewer

# JS source for viewer
site_gen/viewer.js: hx_src/autotude/proto/ build_viewer.hxml \
	$(wildcard hx_src/autotude/**) \
	$(wildcard hx_src/autotude/viewer/**) \
	out/polys
	mkdir -p $(@D)
	haxe build_viewer.hxml

# index and recordings
site_gen/: site_gen/viewer.js site_src/index.sql site_src/make_index.py
	cp site_src/viewer.html $@viewer.html
	mkdir -p $@recordings
	python3 site_src/make_index.py

upload: site_gen/
	scp -r site_gen/* root@cgad.ski:/www/alti_viewer/
