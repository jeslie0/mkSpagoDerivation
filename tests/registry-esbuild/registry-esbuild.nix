{ mkSpagoDerivation, esbuild, purs-backend-es, spago, purs }:
mkSpagoDerivation {
  spagoYaml = ./spago.yaml;
  src = ./.;
  pname = "registry-esbuild-test";
  version = "0.1.0";
  nativeBuildInputs = [ esbuild spago purs purs-backend-es ];
  buildPhase = "spago build && purs-backend-es bundle-app --no-build --minify --to=main.min.js";
  installPhase = "mkdir $out; cp -r main.min.js $out";
}
