{ self, lib, fromYAML, mkDerivation, registry, registry-index }@env:

# This function takes in a spago.yaml file and returns a function that
# takes a package to its derivation and dependencies.
spagoNix :
let
  packageSet =
    spagoNix.workspace.package_set;

  typesNix =
    import "${self}/nix/types.nix";

  registrySpecifiedTypes =
    typesNix.registrySpecified;

  # Type of registry specified in spagoYaml.
  registrySpecifiedType =
    if packageSet ? "registry"
    then registrySpecifiedTypes.registryVersion
    else
      if packageSet ? "url" && packageSet ? "hash"
      then registrySpecifiedTypes.remoteURLHash
      else
        if packageSet ? "path"
        then registrySpecifiedTypes.localFile
        else
          throw
            ''
Could not determine the type of registry in given spago.yaml file.
Please make sure that either a "registry" key, a "path" key corresponding
to a local package set, or a remote "url" and "hash" keys are set in the
workspace.package_set list of keys.
'';

  registryNix =
      if registrySpecifiedType == registrySpecifiedTypes.registryVersion
      then
        (builtins.fromJSON
          (builtins.readFile "${registry}/package-sets/${packageSet.registry}.json")).packages
      else
        if registrySpecifiedType == registrySpecifiedTypes.localFile
        then
          let
            regNix =
              builtins.fromJSON (builtins.readFile "${packageSet.path}");
          in
            if regNix ? "packages"
            then regNix.packages
            else
              throw
                ''
Could not find "packages" in specified registry. Legacy registries are not currently supported.
Please use a modern registry set, or build using a lock file.''
        else
          if registrySpecifiedType == registrySpecifiedTypes.remoteURLHash
          then
            throw
              ''
Remote package sets are not currently supported. Either download the package set
to a JSON file and point workspace.package_set.path to it, or specify a registry
version.
''
          else
            throw
              ''Cannot determine registry type.'';


  fetchRegistryPackageWithVersion =
    { pname, version }:
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
              (str: builtins.isString str && str != "")
              splitFile);

      registryIndexJson =
        lib.lists.findSingle
            (json: json.version == version)
            (throw "No packages in registry index found for package ${pname}-${version}.")
            (throw "Multiple packages in registry index found for package ${pname}-${version}.")
            jsonArray;

      dependencies =
        builtins.attrNames (registryIndexJson.dependencies);

      packageDerivation =
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

        in
          mkDerivation {
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
      { inherit packageDerivation dependencies; };


  fetchRegistryPackageWithGit =
    { pname, git, ref, subdir ? ".", dependencies ? [] }:
    let
      src =
        builtins.fetchGit {
          url =
            git;

          rev =
            ref;
        };

      packageSpagoYamlPath =
        "${src}/${subdir}/spago.yaml";

      packageSpagoYamlExists =
        builtins.pathExists packageSpagoYamlPath;

      packageSpagoNix =
        fromYAML (builtins.readFile "${src}/${subdir}/spago.yaml");

    in
      if
        packageSpagoYamlExists

      then
        import "${self}/nix/getRegistryDerivation" env packageSpagoNix

      else
        throw
          ''Could not find spago.yaml file in "${src}/${subdir}"'';

in
packageName:
if
  builtins.isString registryNix.${packageName}

then
  fetchRegistryPackageWithVersion { pname = packageName; version = registryNix.${packageName}; }

else
  if
    !builtins.isAttrs

  then
    throw
      "Could not determine package type of ${packageName} in registry."

  else
    if
      registryNix.${packageName} ? "git" && registryNix.${packageName} ? "ref"

    then
      fetchRegistryPackageWithGit { pname = packageName; } // registryNix.${packageName}

    else
        throw
          "Package type of ${packageName} in registry is not valid."
