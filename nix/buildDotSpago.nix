{ lib, mkDerivation }:
{ spagoLock }:
mkDerivation {
  name =
    "dot-spago";

  src =
    ./.;

  buildPhase =
    import ./buildFromLockFile.nix { inherit mkDerivation lib; } { spagoLockFile = spagoLock; };

  installPhase =
    ''
      mkdir $out
      cp -r .spago $out
    '';
}
