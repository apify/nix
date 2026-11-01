# Apify Nix packages

Nix packages for Apify tools:

- `apify-cli`: the [Apify CLI](https://docs.apify.com/cli)
- `mcpc`: [mcpc](https://github.com/apify/mcpc), a command-line client for MCP servers

Supported systems: `x86_64-linux`, `aarch64-linux` and `aarch64-darwin`.

## Run a tool once

```sh
nix run github:apify/nix#apify-cli -- --help
nix run github:apify/nix#mcpc -- --help
```

## Add the tools to your configuration

Add this repo as a flake input:

```nix
{
  inputs.apify.url = "github:apify/nix";
  inputs.apify.inputs.nixpkgs.follows = "nixpkgs";
}
```

Then add the packages to NixOS, nix-darwin or home-manager:

```nix
# NixOS or nix-darwin
environment.systemPackages = [ inputs.apify.packages.${pkgs.stdenv.hostPlatform.system}.apify-cli ];

# home-manager
home.packages = [ inputs.apify.packages.${pkgs.stdenv.hostPlatform.system}.apify-cli ];
```

You can also use the overlay, which adds `pkgs.apify-cli` and `pkgs.mcpc`:

```nix
nixpkgs.overlays = [ inputs.apify.overlays.default ];
environment.systemPackages = [ pkgs.apify-cli ];
```

## Updates

Update the CLI by updating the flake input, not with `apify upgrade`. The package turns off the CLI's update notice because the notice tells users to update with npm.

A workflow checks npm for new releases every day and opens a PR. The PR merges after CI builds and tests the package on all supported systems. To update by hand:

```sh
nix develop -c scripts/update.sh <package> [version]
```
