let
  pkgs = import ./nix;
  default = import ./default.nix;
in
  pkgs.mkShell {
    packages =
      default.buildInputs
      ++ (with pkgs; [
        nurl
        haxePackages.heaps
        haxePackages.hxcpp
        updog
      ]);
  }
