let
  pkgs = import ./nix;

in
  with pkgs; rec {
    buildInputs = [
      # protobuf
      protobuf
      jre8

      # haxe
      haxe
      neko
    ] ++ (with haxePackages; [
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
          cp -r ./hx_src $out/
          cp ./haxelib.json $out/
        '';
      };
    };

    inherit (haxePackages) protohx;
  }
