set dotenv-load

default:
    just --list

# Download and unpack resources, including .jar for server.
setup:
	wget https://cgad.ski/autotude-dist.tar -O dist.tar
	tar -xvf dist.tar
	rm dist.tar
	mkdir -p bin/
	ln -sf $PWD/java_dist/BotServer*/bin/BotServer bin/server

# Install dependencies through nix
nix:
	nix build -L -f . env -o etc/nix.env

# Copy game files from Altitude source tree at $ALTI_SRC
setup-from-src:
	if [ -z "$ALTI_SRC" ]; then \
		echo "ALTI_SRC not set"; \
		exit 1; \
	fi
	mkdir -p java_dist/
	mkdir -p bin/
	tar -xf $ALTI_SRC/BotServer/build/distributions/*.tar -C java_dist/
	tar -xf $ALTI_SRC/BotClient/build/distributions/*.tar -C java_dist/
	ln -sf $PWD/java_dist/BotServer*/bin/BotServer bin/server
	ln -sf $PWD/java_dist/BotClient*/bin/BotClient bin/client
	rsync -ru \
		$ALTI_SRC/BotServer/build/alti_home/{maps,resources,data} \
		alti_home/
	rm -rf alti_home/resources/dist/{.image,.sound}

JAVA_INSTALL := env_var_or_default("ALTI_SRC", "") + "/Altitude/src/main/java/em/altitude/game/protos/"

# Copy generated java files into Altitude source tree
export-java-gen:
	if [ -z "$ALTI_SRC" ]; then \
		echo "ALTI_SRC not set"; \
		exit 1; \
	fi
	make java_gen/
	rm -rf {{JAVA_INSTALL}}
	mkdir -p {{JAVA_INSTALL}}
	cp java_gen/em/altitude/game/protos/* {{JAVA_INSTALL}}

# Package and upload resources.
dist:
	tar -czf dist.tar \
		alti_home/{maps,resources,data}/ \
		java_dist/BotServer* \
		hx_src/out/viewer.js
	rsync -v --progress dist.tar root@cgad.ski:/www/autotude-dist.tar


# Package and upload recordings
dist-recordings:
	tar -cf recordings.tar recordings/*
	rsync -v --progress recordings.tar root@altistats.com:/root/files/recordings.tar

# Download recordings from altistats.com
dl:
	mkdir -p ${REPLAY_DIR}
	rsync --progress -av root@altistats.com:/root/alti_home/recordings/ ${REPLAY_DIR}
