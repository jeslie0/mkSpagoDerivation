{ stdenv, registry, registry-index, lib }@constArgs:
{ spagoNix
, symlink ? false}:

let
  # Symlink or copy command.
  command =
    if symlink
    then "ln -s"
    else "cp -r";

  # Takes a package and version and returns a derivation.
  makePackageDerivation = { pname, version, ...}:
    let
      metadataNix =
        builtins.fromJSON (builtins.readFile "${registry}/metadata/${pname}.json");

      packageInfo =
        metadataNix.published.${version};

      src =
        builtins.fetchurl {
          url = "https://packages.registry.purescript.org/${pname}/${version}.tar.gz";
          sha256 = packageInfo.hash;
        };

      pkgDerivation =
        stdenv.mkDerivation {
          inherit pname;

          version =
            packageInfo.ref;

          src =
            src;

          installPhase =
            ''
            mkdir $out
            cp -r * $out/
            '';
        };
    in
      { inherit pname version pkgDerivation; };

  # Array of all dependencies for the package
  # [{pname, version}]
  fullDependencyArray =
    builtins.attrValues
      ((import ./registry.nix constArgs spagoNix).dependencyArray { extraPackageNames = ["psci-support"]; });

  # Array of derivations for the dependencies
  derivationArray =
    builtins.map makePackageDerivation fullDependencyArray;

  # List of commands used to put each dependency in the correct place.
  commandsList =
    builtins.map
      (package: ''
          mkdir -p .spago/packages/${package.pname}-${package.version};
          ${command} ${package.pkgDerivation}/* .spago/packages/${package.pname}-${package.version};
          '')
      derivationArray;
in
stdenv.mkDerivation {
  name =
    "${spagoNix.package.name}-dot-spago";

  src = ./.;

  buildPhase =
    lib.concatStrings commandsList;

  installPhase =
    ''
    mkdir $out;
    cp -r .spago $out;
    '';
}
