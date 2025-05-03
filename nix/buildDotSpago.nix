{ self, lib, mkDerivation, registry, registry-index }:
{ spagoLock }:
mkDerivation {
  name =
    "dot-spago";

  src =
    ./.;

  buildPhase =
    import ./buildFromLockFile.nix { inherit mkDerivation registry lib; } { spagoLockFile = spagoLock; };

  installPhase =
    ''
      mkdir $out
      cp -r .spago $out
    '';
}
