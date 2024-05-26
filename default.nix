let
  pkgs = import ./nix;
in
  with pkgs; rec {
    buildInputs = [
      # for protobuf
      protobuf
      jre8

      # dependencies
      haxe
      haxePackages.protohx
      haxePackages.format

      # for running tools
      neko
    ];

    polys = stdenv.mkDerivation {
      name = "polys";
      src = ./.;

      inherit buildInputs;

      buildPhase = ''
        make clean out/polys
      '';

      installPhase = ''
        cp out/polys $out
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
