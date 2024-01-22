{ buildDotSpago }:
buildDotSpago {
  src = ./.;
  spagoLock = ./spago.lock;
}
