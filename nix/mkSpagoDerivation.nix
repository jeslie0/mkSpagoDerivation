{ stdenv, fromYAML, buildSpagoNodeJs, registry, registry-index, git, lib }:
{ src

, spagoYaml ? "${src}/spago.yaml"

, spagoLock ? "${src}/spago.lock"

, nativeBuildInputs ? []

, ...} @ args:
let
  spagoNix =
    fromYAML (builtins.readFile spagoYaml);

  spagoNodeJs =
    buildSpagoNodeJs { symlink = false; };

  pname =
    if builtins.hasAttr "pname" args
    then args.pname
    else spagoNix.package.name;

  version =
    if builtins.hasAttr "version" args
    then "-${args.version}"
    else
      if builtins.hasAttr "pname" args
      then throw "specify version or just use \"name\""
      else "";

  name =
    if builtins.hasAttr "name" args
    then args.name
    else "${pname}${version}";

  buildPhase =
    let
      buildCommand =
        if builtins.hasAttr "buildPhase" args
        then args.buildPhase
        else "";

      dotSpagoCommand =
        import ./buildFromLockFile.nix { inherit registry lib; mkDerivation = stdenv.mkDerivation; } { inherit src; spagoLockFile = spagoLock; };
    in
      ''
        runHook preBuild
        export HOME=$(mktemp -d)
        mkdir -p $HOME/.cache/spago-nodejs
        cp -r ${spagoNodeJs}/spago-nodejs/* $HOME/.cache/spago-nodejs
        ${dotSpagoCommand}
        ${buildCommand}
        runHook postBuild
        '';

  installPhase =
    if builtins.hasAttr "installPhase" args
    then
      ''
      runHook preInstall
      ${args.installPhase}
      runHook postInstall
      ''
    else
      ''
      runHook preInstall
      runHook postInstall
      '';
in
stdenv.mkDerivation (args // {
  inherit name buildPhase installPhase;
  nativeBuildInputs =
    [ (if builtins.hasAttr "git" args then args.git else git)
    ] ++ nativeBuildInputs;
})
