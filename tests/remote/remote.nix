{ mkSpagoDerivation, spago, purs, esbuild }:
mkSpagoDerivation {
  pname = "remote-package-test";
  version = "0.1.0";
  src = ./.;
  nativeBuildInputs = [ esbuild spago purs ];
  spagoYaml = ./spago.yaml;
  spagoLock = ./spago.lock;
  buildPhase = "spago bundle";
  installPhase = "mkdir $out; cp index.js $out";
}
