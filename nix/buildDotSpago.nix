{ self, lib, fromYAML, mkDerivation, registry, registry-index }:
{ spagoLockFile, src }:
mkDerivation {
  name =
    "dot-spago";

  src =
    src;

  buildPhase =
    import ./buildFromLockFile.nix { inherit fromYAML mkDerivation registry lib; symlink = false; } { inherit src spagoLockFile; };

  installPhase =
    ''
      mkdir $out
      cp -r .spago $out
    '';
}
