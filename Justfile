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
	mkdir -p bin/
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
