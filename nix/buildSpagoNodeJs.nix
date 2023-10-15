{ stdenv, registry, registry-index }:
{ symlink ? false }:
let
  command =
    if symlink
    then "ln -s"
    else "cp -r";
in
stdenv.mkDerivation {
  name = "spagoNodeJs";
  src = ./.;
  installPhase =
  ''
  mkdir -p $out/spago-nodejs;
  mkdir $out/spago-nodejs/registry;
  ${command} ${registry}/* $out/spago-nodejs/registry
  mkdir $out/spago-nodejs/registry-index;
  ${command} ${registry-index}/* $out/spago-nodejs/registry-index
  touch $out/spago-nodejs/fresh-registry-canary.txt
  '';
}
