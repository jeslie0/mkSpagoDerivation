{ mkSpagoDerivation, esbuild }:
mkSpagoDerivation {
  pname = "local-package-test";
  version = "0.1.0";
  src = ./.;
  nativeBuildInputs = [ esbuild ];
  spagoYaml = ./spago.yaml;
  spagoLock = ./spago.lock;
  buildPhase = "spago bundle";
  installPhase = "mkdir $out; cp index.js $out";
}
