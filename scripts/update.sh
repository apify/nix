#!/usr/bin/env bash
# Usage: scripts/update.sh <package> [version]
# Updates pkgs/<package> to the given npm version (default: the latest release on npm).
# Needs nix, npm, jq, curl and prefetch-npm-deps; `nix develop` provides them.
set -euo pipefail
cd "$(dirname "$0")/.."

name=${1:?Usage: scripts/update.sh <package> [version]}
case $name in
  apify-cli) npm_name=apify-cli ;;
  mcpc) npm_name=@apify/mcpc ;;
  *)
    echo "Unknown package: $name" >&2
    exit 1
    ;;
esac

pkg=pkgs/$name
version=${2:-$(npm view "$npm_name" version)}
if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Not a release version: $version" >&2
  exit 1
fi

current=$(sed -n 's/^  version = "\(.*\)";$/\1/p' "$pkg/package.nix")
if [[ $version == "$current" ]]; then
  echo "$name is already at $version"
  exit 0
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

url=$(npm view "$npm_name@$version" dist.tarball)
curl -fsSL "$url" | tar xz -C "$work"

jq 'del(.devDependencies, .devEngines, .scripts)' "$work/package/package.json" > "$pkg/package.json"
cp "$pkg/package.json" "$work/package/package.json"
(cd "$work/package" && npm install --package-lock-only --ignore-scripts --no-audit --no-fund > /dev/null)
cp "$work/package/package-lock.json" "$pkg/package-lock.json"

src_hash=$(nix store prefetch-file --json "$url" | jq -r .hash)
deps_hash=$(prefetch-npm-deps "$pkg/package-lock.json")

sed -i \
  -e "s|^  version = \".*\";$|  version = \"$version\";|" \
  -e "0,/hash = \"sha256-[^\"]*\";/s||hash = \"$src_hash\";|" \
  -e "s|npmDepsHash = \".*\";|npmDepsHash = \"$deps_hash\";|" \
  "$pkg/package.nix"

nix build ".#$name" --no-link -L
echo "Updated $name from $current to $version"
