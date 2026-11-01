{
  lib,
  buildNpmPackage,
  fetchurl,
  nodejs,
  makeWrapper,
  versionCheckHook,
}:

buildNpmPackage (finalAttrs: {
  pname = "apify-cli";
  version = "1.11.0";

  # The npm release already contains the built CLI, with its version and commit filled in.
  src = fetchurl {
    url = "https://registry.npmjs.org/apify-cli/-/apify-cli-${finalAttrs.version}.tgz";
    hash = "sha256-vbKt/DdK64duDRg8bE+0l1aRt5Wm4otXWKvyJ30Vu3A=";
  };

  # The npm release has no lockfile. scripts/update.sh generates both files.
  postPatch = ''
    cp ${./package.json} package.json
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-loTrsZwFVlpts0UL36IaxPsP44givbkYKDfWQQnlJhc=";

  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  # The CLI's update notice tells users to update with npm.
  postInstall = ''
    for bin in apify apify-cli actor; do
      wrapProgram $out/bin/$bin --set-default APIFY_CLI_SKIP_UPDATE_CHECK 1
    done
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";

  # When the keyring module fails to load, the CLI silently stores the token in a plain file.
  postInstallCheck = ''
    export HOME=$(mktemp -d) APIFY_CLI_DISABLE_TELEMETRY=1
    (cd $HOME && $out/bin/apify init -y testing-actor && test -f .actor/actor.json)
    (cd $out/lib/node_modules/apify-cli && ${lib.getExe nodejs} -e "require('@napi-rs/keyring')")
  '';

  meta = {
    description = "Command-line interface for the Apify platform";
    homepage = "https://docs.apify.com/cli";
    changelog = "https://github.com/apify/apify-cli/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    mainProgram = "apify";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
})
