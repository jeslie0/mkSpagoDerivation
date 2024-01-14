{ mkSpagoDerivation, esbuild }:
mkSpagoDerivation {
  name = "monorepo-test";
  version = "0.1.0";
  src = ./.;
  spagoLock = ./spago.lock;
  nativeBuildInputs = [ esbuild ];
  buildPhase = "spago bundle -p main";
  installPhase = "mkdir $out; cp Main/index.js $out";
}
