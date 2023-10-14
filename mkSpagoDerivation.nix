{ stdenv, fromYAML, buildDotSpago, buildSpagoNodeJs, registry, registry-index, spago, purs, git }:
{ src

, spagoYamlFile ? "${src}/spago.yaml"

, nativeBuildInputs ? []

, ...} @ args:
let
  spagoNix =
    fromYAML (builtins.readFile spagoYamlFile);

  dotSpago =
    buildDotSpago spagoNix;

  spagoNodeJs =
    buildSpagoNodeJs;

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


  output =
    if builtins.hasAttr "build_opts" spagoNix.workspace
       && builtins.hasAttr "output" spagoNix.workspace.build_opts
    then spagoNix.workspace.build_opts
    else "output*";

  buildPhase =
    let
      buildCommand =
        if builtins.hasAttr "buildPhase" args
        then args.buildPhase
        else "spago build";
    in
      ''
        runHook preBuild
        mkdir .spago
        cp -r ${dotSpago}/.spago .
        export HOME=$(mktemp -d)
        mkdir $HOME/.cache
        cp -r ${spagoNodeJs}/* $HOME/.cache
        ${buildCommand}
        runHook postBuild
        '';

  installPhase =
    if builtins.hasAttr "installPhase" args
    then args.installPhase
    else
      ''
      runHook preInstall
      mkdir $out
      cp -r ${output} $out
      runHook postInstall
      '';
in
stdenv.mkDerivation (args // {
  inherit name buildPhase installPhase;
  nativeBuildInputs =
    [ (if builtins.hasAttr "git" args then args.git else git)
      (if builtins.hasAttr "purs" args then args.purs else purs)
      (if builtins.hasAttr "spago" args then args.spago else spago)
    ] ++ nativeBuildInputs;
})
