#!/usr/bin/env bash
# Usage: scripts/update.sh [version]
# Updates pkgs/apify-cli to the given npm version (default: the latest release on npm).
# Needs nix, npm, jq, curl and prefetch-npm-deps; `nix develop` provides them.
set -euo pipefail
cd "$(dirname "$0")/.."

pkg=pkgs/apify-cli
version=${1:-$(npm view apify-cli version)}
if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Not a release version: $version" >&2
  exit 1
fi

current=$(sed -n 's/^  version = "\(.*\)";$/\1/p' "$pkg/package.nix")
if [[ $version == "$current" ]]; then
  echo "apify-cli is already at $version"
  exit 0
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

url="https://registry.npmjs.org/apify-cli/-/apify-cli-$version.tgz"
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

nix build ".#apify-cli" --no-link -L
echo "Updated apify-cli from $current to $version"
