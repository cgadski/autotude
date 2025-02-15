let
  sources = import ./sources.nix;
in
  import sources.nixpkgs {
    overlays = [
      (self: super: {
        protobuf = super.protobuf.override {
          version = "28.3";
          hash = "sha256-+bb5RxITzxuX50ItmpQhWEG1kMfvlizWTMJJzwlhhYM=";
        };
        haxePackages = super.haxePackages
          // super.callPackage ./haxe-packages.nix {};
      })
    ];
  }
