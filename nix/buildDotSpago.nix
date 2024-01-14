{ self, lib, fromYAML, mkDerivation, registry, registry-index }:
{ spagoLock, src }:
mkDerivation {
  name =
    "dot-spago";

  src =
    src;

  buildPhase =
    import ./buildFromLockFile.nix { inherit fromYAML mkDerivation registry lib; symlink = false; } { inherit src; spagoLockFile = spagoLock; };

  installPhase =
    ''
      mkdir $out
      cp -r .spago $out
    '';
}
