{ mkSpagoDerivation }:
mkSpagoDerivation {
  name = "monorepo-test";
  version = "0.1.0";
  src = ./.;

  spagoLock = ./spago.lock;
}
