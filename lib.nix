{ fromYaml, registry, registry-index, stdenv, spagoDotYaml }:
let
  spagoNix =
    fromYaml spagoDotYaml;

  getDependencyInformation =
    let
      registryVersion =
        spagoNix.workspace.package_set.registry;

      registryPath =
        "${registry}/package-sets/${registryVersion}.json";

      dependencyNamesArray =
        spagoNix.package.dependencies;

      registryNixPackages =
        (builtins.fromJSON (builtins.readFile registryPath)).packages;

    in
      builtins.map (pname: { inherit pname; version = registryNixPackages.${pname}; }) dependencyNamesArray;

  makePackageDerivation = package:
    let
      metadataNix =
        builtins.fromJSON (builtins.readFile "${registry}/metadata/${package.pname}.json");

      packageInfo =
        metadataNix.published.${package.version};

      src =
        builtins.fetchurl {
          url = "https://packages.registry.purescript.org/${package.pname}/${package.version}.tar.gz";
          sha256 = packageInfo.hash;
        };

      pkgDerivation =
        stdenv.mkDerivation {
          pname =
            package.pname;

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
      { pname = package.pname; version = package.version; pkgDerivation = pkgDerivation; };
in
 {
  buildDotSpago =
    let
      packages =
        getDependencyInformation;

      derivationArray =
        builtins.map makePackageDerivation packages;

      commandsList =
        builtins.map
          (package: ''
          mkdir -p .spago/packages/${package.pname}-${package.version};
          cp -R ${package.pkgDerivation}/* .spago/packages/${package.pname}-${package.version};
          '')
          derivationArray;
    in
      stdenv.mkDerivation {
        name =
          "${spagoNix.package.name}-dot-spago";

        src = ./.;

        buildPhase =
          stdenv.lib.concatStrings commandsList;

        installPhase =
          ''
          mkdir $out;
          cp -r .spago $out;
          '';
      };

  buildSpagoNodeJs = stdenv.mkDerivation {
    name = "spagoNodeJs";
    src = ./.;
    installPhase =
      ''
      mkdir -p $out/spago-nodejs;
      mkdir $out/spago-nodejs/registry;
      cp -R ${registry}/* $out/spago-nodejs/registry
      mkdir $out/spago-nodejs/registry-index;
      cp -R ${registry-index}/* $out/spago-nodejs/registry-index
      touch $out/spago-nodejs/fresh-registry-canary.txt
      '';
  };
}
