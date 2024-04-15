{
  stdenv,
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
in {
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

    buildPhase = ''
      (cd tools/hxcpp; haxe compile.hxml)
    '';

    postFixup = ''
      for f in $out/lib/haxe/${withCommas libname}/${withCommas version}/{,project/libs/nekoapi/}bin/Linux{,64}/*; do
        chmod +w "$f"
        patchelf --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker)   "$f" || true
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

  hxmustache = buildHaxeLib {
    src = fetchFromGitHub {
      owner = "nadako";
      repo = "hxmustache";
      rev = "756b3880da5035a18909ac4865adc7615c862f79";
      hash = "sha256-r1BhW+DrrUp0nAyZQgSuBbIEoiSRjFTLiE16c4AlfRM=";
    };
    libname = "hxmustache";
    version = "0.2.2";
  };
}
