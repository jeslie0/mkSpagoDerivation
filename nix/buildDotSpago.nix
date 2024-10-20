{ self, lib, mkDerivation, registry, registry-index }:
{ spagoLock, src }:
mkDerivation {
  name =
    "dot-spago";

  src =
    src;

  buildPhase =
    import ./buildFromLockFile.nix { inherit mkDerivation registry lib; } { inherit src; spagoLockFile = spagoLock; };

  installPhase =
    ''
      mkdir $out
      cp -r .spago $out
    '';
}
