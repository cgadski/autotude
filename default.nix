let
  pkgs = import ./nix;

in
  with pkgs; rec {
    buildInputs = [
      # protobuf
      protobuf
      jdk23

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
        src = ./.;
        buildInputs = lib.lists.remove neko buildInputs;

        buildPhase = ''
          make clean hx_src/autotude/proto/
        '';

        installPhase = ''
          mkdir -p $out
          rm ./hx_src/protohx.json
          rm ./hx_src/clean_hxproto.sh
          cp -r ./hx_src $out/
          cp ./hx_src/haxelib.json $out/
        '';
      };
    };

    inherit (haxePackages) protohx;
  }
