{
  stdenv,
  darwin,
  xcbuild,
  lib,
  fetchzip,
  fetchFromGitHub,
  haxe,
  neko,
  patchelf,
}: let
  withCommas = lib.replaceStrings ["."] [","];

  installLibHaxe = {
    libname,
    version,
    files ? "*",
  }: ''
    mkdir -p "$out/lib/haxe/${withCommas libname}/${withCommas version}"
    echo -n "${version}" > $out/lib/haxe/${withCommas libname}/.current
    cp -dpR ${files} "$out/lib/haxe/${withCommas libname}/${withCommas version}/"
  '';

  buildHaxeLib = {
    libname,
    version,
    meta ? {},
    ...
  } @ attrs:
    stdenv.mkDerivation (attrs
      // {
        name = "${libname}-${version}";

        buildInputs = (attrs.buildInputs or []) ++ [haxe neko patchelf]; # for setup-hook.sh to work
        src =
          attrs.src
          or (fetchzip rec {
            name = "${libname}-${version}";
            url = "http://lib.haxe.org/files/3.0/${withCommas name}.zip";
            inherit (attrs) sha256;
            stripRoot = false;
          });

        installPhase =
          attrs.installPhase
          or ''
            runHook preInstall
            (
              if [ $(ls | wc -l) == 1 ]; then
                cd *
              fi
              ${installLibHaxe {inherit libname version;}}
            )
            runHook postInstall
          '';
      });
in rec {
  inherit buildHaxeLib;

  protohx = buildHaxeLib rec {
    src = fetchFromGitHub {
      owner = "nitrobin";
      repo = "protohx";
      rev = "ce7b7ac49a676fd29d08184148eefbeb4c0cba47";
      hash = "sha256-BnGmX4GCQ307X7d7BQbkzu3oPp3CpfcknV4EY1nvhc0=";
    };

    patches = [./protohx.diff];
    installPhase = installLibHaxe {inherit libname version;};

    buildPhase = ''
      (cd tools/run; haxe build.hxml)
    '';

    libname = "protohx";
    version = "0.4.6";
  };

  hxcpp = buildHaxeLib rec {
    libname = "hxcpp";
    version = "4.3.0";

    src = fetchFromGitHub {
      owner = "HaxeFoundation";
      repo = "hxcpp";
      rev = "3b183115466c417a445cb7b984ab6138ec21330e";
      hash = "sha256-+Uue7pdkl67hRq6RXdao/ayFR75ExfoDDIhSB9EOQM0=";
    };

    # patches = [ ./hxcpp.diff ];

    buildPhase = ''
      (cd tools/hxcpp; haxe compile.hxml)
    '';

    postFixup = ''
      for f in $out/lib/haxe/${withCommas libname}/${withCommas version}/{,project/libs/nekoapi/}bin/Linux{,64}/*; do
        chmod +w "$f"
        patchelf --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) "$f" || true
        patchelf --set-rpath ${lib.makeLibraryPath [stdenv.cc.cc]}  "$f" || true
      done
    '';
    meta.description = "Runtime support library for the Haxe C++ backend";
  };

  heaps = buildHaxeLib {
    libname = "heaps";
    version = "2.0.0";
    sha256 = "sha256-LQ98Kt+H5E4AG5HwsByTxRRZQIr73bQaHPXcRklekjs=";
    meta.description = "The GPU Game Framework";
  };

  format = buildHaxeLib {
    libname = "format";
    version = "3.7.0";
    sha256 = "sha256-/xXMP/UkLOXd9Qs43d3APjDZ3c0TZV0NqXCIrqmsaj0=";
    meta.description = "A Haxe Library for supporting different file formats";
  };

  tokentree = buildHaxeLib {
    libname = "tokentree";
    version = "1.2.11";
    src = fetchFromGitHub {
      owner = "HaxeCheckstyle";
      repo = "tokentree";
      rev = "6032e8071073fa01449f51acfdc02a1a610d35e0";
      hash = "sha256-lVdu9Jhs4NT1w5S5C1OgMmj07DikxX2qO+vtu3DyxaY=";
    };
  };

  haxeparser = buildHaxeLib {
    libname = "haxeparser";
    version = "4.3.0";
    src = fetchFromGitHub {
      owner = "HaxeCheckstyle";
      repo = "haxeparser";
      rev = "a5fce2ecf5fb3bdfebfd7efd8b05329d456ec0d2";
      hash = "sha256-voQZT9BJRqlqyc8eFQyjAsr/LBgkY2NZJfFzpkMx/14=";
    };
  };

  hxparse = buildHaxeLib {
    libname = "hxparse";
    version = "4.3.0";
    sha256 = "sha256-3r351fSXC1AY9zOhZU1SEKyovxSEiay0B/Si7TP+tG4=";
  };

  json2object = buildHaxeLib {
    libname = "json2object";
    version = "3.11.0";
    sha256 = "sha256-M2iJZjI9Un6QOIWd/7Qv0XsQSntq3JJmXwTIzBSEXCo=";
  };

  hxargs = buildHaxeLib {
    libname = "hxargs";
    version = "4.0.0";
    sha256 = "sha256-RIy7Mai2MsmjC0A6F0sCeQu7XQaRjUYiHxVpgTrUSnY=";
  };

  hxjsonast = buildHaxeLib {
    libname = "hxjsonast";
    version = "1.1.0";
    sha256 = "sha256-5Kbq/hDKypx29omnU8bFfd634KqBVYybEmUZh13qjYc=";
  };

  formatter = stdenv.mkDerivation {
    name = "formatter";

    buildPhase = ''
      haxe buildCpp.hxml
    '';

    installPhase = ''
      mkdir -p $out/bin/
      cp out/formatter $out/bin/hx-fmt
    '';

    HXCPP_CLANG = true;

    buildInputs = [
      darwin.apple_sdk.frameworks.Cocoa
      haxe hxcpp xcbuild
      tokentree haxeparser hxparse json2object hxargs hxjsonast
    ];

    src = fetchFromGitHub {
      owner = "HaxeCheckstyle";
      repo = "haxe-formatter";
      rev = "7e4984fe5a894a4f1178d9d05d81e3ea2bd8546b";
      hash = "sha256-7h5TEUJ4eKXSheLjxE/Skleb5CRD+eZPtTh+cORLnyU=";
    };
  };
}
