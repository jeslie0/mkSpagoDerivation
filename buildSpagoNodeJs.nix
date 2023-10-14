{ stdenv, registry, registry-index }:

stdenv.mkDerivation {
  name = "spagoNodeJs";
  src = ./.;
  installPhase =
  ''
  mkdir -p $out/spago-nodejs;
  mkdir $out/spago-nodejs/registry;
  cp -R ${registry}/* $out/spago-nodejs/registry
  mkdir $out/spago-nodejs/registry-index;
  cp -R ${registry-index}/* $out/spago-nodejs/registry-index
  touch $out/spago-nodejs/fresh-registry-canary.txt
  '';
}
