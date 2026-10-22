let
  pkgs = import ./nix;

in
  with pkgs; rec {
    buildInputs = [
      # protobuf
      protobuf
      jdk23
      mypy-protobuf

      # haxe
      haxe
      neko

      # ruff
      ruff
    ] ++ (with haxePackages; [
      formatter
      protohx
      format
      heaps
      hxcpp
    ]);

    env = pkgs.runCommand "env" { inherit buildInputs; } ''
      echo "PATH_add \"$PATH\"" > $out
      echo "export HAXELIB_PATH=$HAXELIB_PATH" >> $out
    '';

    polys = stdenv.mkDerivation {
      name = "polys";
      src = ./.;

      inherit buildInputs;

      buildPhase = ''
        make clean data/polys
      '';

      installPhase = ''
        cp data/polys $out
      '';
    };

    autotude = haxePackages.buildHaxeLib {
      libname = "autotude";
      version = "1.0.0";
      src = stdenv.mkDerivation {
        name = "src";
        src = fetchTree {
          url = ./.;
          type = "git";
        };
        buildInputs = lib.lists.remove neko buildInputs;

        buildPhase = ''
          make clean viewer/autotude/proto/
        '';

        installPhase = ''
          mkdir -p $out
          rm ./viewer/protohx.json
          rm ./viewer/clean_hxproto.sh
          cp -r ./viewer $out/
          cp ./viewer/haxelib.json $out/
        '';
      };
    };

    inherit (haxePackages) protohx;
  }
