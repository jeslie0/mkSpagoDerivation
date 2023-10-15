{ stdenv, registry, registry-index, lib }:
{ spagoNix
, symlink ? false}:

let
  command =
    if symlink
    then "ln -s"
    else "cp -r";

  registryVersion =
    spagoNix.workspace.package_set.registry;

  registryPath =
    "${registry}/package-sets/${registryVersion}.json";

  registryNixPackages =
    (builtins.fromJSON (builtins.readFile registryPath)).packages;


  # We start by getting the direct package dependencies from the
  # spago.yaml file. We then need to get all of this package's
  # dependencies and store them. This is an iterative/recursive
  # process and we are finished when we have a complete list of
  # packages. We can use the package set to find the desired version.
  # {pname, version} -> [{ pname, version }]
  getPackageDependencies = { pname, version }:
    let
      nameLength =
        builtins.stringLength pname;

      firstTwoChars =
        builtins.substring 0 2 pname;

      firstChar =
        builtins.substring 0 1 pname;

      nextTwoChars =
        builtins.substring 2 2 pname;

      indexFile =
        if nameLength <= 2
        then "${registry-index}/2/${pname}"
        else
          if nameLength <= 3
          then "${registry-index}/3/${firstChar}/${pname}"
          else "${registry-index}/${firstTwoChars}/${nextTwoChars}/${pname}";

      jsonArray =
        let
          splitFile =
            (lib.strings.split
              "\n"
              (builtins.readFile indexFile));
        in
        builtins.map
          (str: builtins.fromJSON str)
          (builtins.filter
            (str: str != "" && builtins.typeOf str =="string")
            splitFile
            );

      correctJson =
        lib.lists.findSingle
          (json: json.version == version)
          null
          null
          jsonArray;

      dependencyNamesArray = builtins.attrNames correctJson.dependencies;
    in
      if correctJson == null
      then throw "Error! Could not find version ${version} of ${pname} in registry-index."
      else
        builtins.map
          (pname: {inherit pname; version = registryNixPackages.${pname}; })
          dependencyNamesArray;

  # [{pname, version}]
  directDependencies =
    let
      dependencyNamesArray =
        spagoNix.package.dependencies;
    in
      builtins.map (pname: { inherit pname; version = registryNixPackages.${pname}; }) dependencyNamesArray;


  buildDependencyAttr = attr: arr:
    builtins.foldl'
      (acc: cur:
        if builtins.hasAttr cur.pname acc
        then acc
        else
          let
            newDeps = getPackageDependencies cur;
          in
            buildDependencyAttr ({${cur.pname} = cur;} //  acc) newDeps
      )
      attr
      arr;

  fullDependencyArray =
    builtins.attrValues
      (buildDependencyAttr {} directDependencies);


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
