{
  description = "Nix packages for Apify tools";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      overlays.default = final: _prev: {
        apify-cli = final.callPackage ./pkgs/apify-cli/package.nix { };
        mcpc = final.callPackage ./pkgs/mcpc/package.nix { };
      };

      packages = forAllSystems (pkgs: rec {
        apify-cli = pkgs.callPackage ./pkgs/apify-cli/package.nix { };
        mcpc = pkgs.callPackage ./pkgs/mcpc/package.nix { };
        default = apify-cli;
      });

      checks = forAllSystems (pkgs: {
        inherit (self.packages.${pkgs.stdenv.hostPlatform.system}) apify-cli mcpc;
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            nodejs
            jq
            curl
            prefetch-npm-deps
          ];
        };
      });
    };
}
