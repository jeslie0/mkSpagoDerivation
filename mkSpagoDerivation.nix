{ stdenv, fromYAML, buildDotSpago, buildSpagoNodeJs, registry, registry-index, spago, purs, git }:
{
  src
, spagoYamlFile ? "${src}/spago.yaml"

, spagoArgs ? ["build"]

, nativeBuildInputs ? []

, pname ? false

, version ? ""

} @ args:
let
  spagoNix =
    fromYAML (builtins.readFile spagoYamlFile);

  dotSpago =
    buildDotSpago spagoNix;

  spagoNodeJs =
    buildSpagoNodeJs;
in
stdenv.mkDerivation (args // {
  name =
    if pname == false then spagoNix.package.name else pname;

  src =
    src;

  nativeBuildInputs =
    [git purs] ++ nativeBuildInputs;

  buildPhase =
    ''
    runHook preBuild;
    mkdir .spago;
    cp -r ${dotSpago}/.spago .;
    export HOME=$(mktemp -d);
    mkdir $HOME/.cache;
    cp -r ${spagoNodeJs}/* $HOME/.cache;
    ${spago}/bin/spago ${builtins.concatStringsSep " " spagoArgs};
    runHook postBuild;
    '';

  installPhase =
    ''
    runHook preInstall
    mkdir $out
    cp -r output $out
    runHook postInstall
    '';
})
