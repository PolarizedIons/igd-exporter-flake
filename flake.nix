{
  description = "igd-exporter flake";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      packages.${system} = rec {
        default = igd-exporter;
        igd-exporter = pkgs.callPackage ./package.nix { };
      };

      nixosModules.${system} = rec {
        default = igd-exporter;
        igd-exporter = import ./module.nix { inherit self system; };
      };

      checks.${system}.test =
        pkgs.callPackage ./test.nix { inherit self system; };
    };
}
