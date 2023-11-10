{ mkSpagoDerivation }:
mkSpagoDerivation {
  pname = "registry-test";
  version = "0.1.0";
  src = ./.;
  spagoYaml = ./spago.yaml;
}
