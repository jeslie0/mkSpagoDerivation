{ stdenv, registry, registry-index, lib }@constArgs:
{ spagoNix
, symlink ? false}:

let
  command =
    if symlink
    then "ln -s"
    else "cp -r";

  makePackageDerivation = { pname, version }:
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
          pname =
            pname;

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

  fullDependencyArray =
    builtins.attrValues
      (import ./buildDependencyAttr.nix constArgs {inherit symlink;} spagoNix ["psci-support"] {});

  derivationArray =
    builtins.map makePackageDerivation fullDependencyArray;

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
