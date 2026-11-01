{
  lib,
  buildNpmPackage,
  fetchurl,
  nodejs,
  versionCheckHook,
}:

buildNpmPackage (finalAttrs: {
  pname = "mcpc";
  version = "0.7.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/@apify/mcpc/-/mcpc-${finalAttrs.version}.tgz";
    hash = "sha256-9ame32MwiUdOPKHb2SjFYOrGPx6KX/LW8Ei5LQzU2ow=";
  };

  # The npm release has no lockfile. scripts/update.sh generates both files.
  postPatch = ''
    cp ${./package.json} package.json
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-UaEewfK3ZwWZEiEptVcuhuj0LB1neJiz6mC2oL/3u2U=";

  dontNpmBuild = true;

  # mcpc starts its bridge with `node dist/bridge/index.js`, never as `mcpc-bridge`.
  postInstall = ''
    rm $out/bin/mcpc-bridge
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";

  # When the keyring module fails to load, mcpc silently stores credentials in a plain file.
  postInstallCheck = ''
    (cd $out/lib/node_modules/@apify/mcpc && ${lib.getExe nodejs} -e "require('@napi-rs/keyring')")
  '';

  meta = {
    description = "Command-line client for the Model Context Protocol (MCP)";
    homepage = "https://github.com/apify/mcpc";
    changelog = "https://github.com/apify/mcpc/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.asl20;
    mainProgram = "mcpc";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
})
