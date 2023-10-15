{ registry, registry-index, lib, ... }:
spagoYaml:
let
  packageSet =
    spagoYaml.workspace.package_set;

  typesNix =
    import ./types.nix;

  registrySpecifiedTypes =
    typesNix.registrySpecified;

  registryEntryTypes =
    typesNix.registryEntry;

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

  registryData = {
      type = registrySpecifiedType;
      registry =
        if registrySpecifiedType == registrySpecifiedTypes.registryVersion
        then
          (builtins.fromJSON
            (builtins.readFile "${registry}/package-sets/${packageSet.registry}.json")).packages
        else
          if registrySpecifiedType == registrySpecifiedTypes.localFile
          then
            builtins.fromJSON (builtins.readFile "${packageSet.path}")
          else
            throw
''
Remote package sets are not currently supported. Either download the package set
to a JSON file and point workspace.package_set.path to it, or specify a registry
version.
'';
  };

  determineRegistryEntryTypeAndVersion = pname:
    let
      registryValue = registryData.registry.${pname};
    in
      if builtins.isString registryValue
      then { inherit pname;
             entryType = registryEntryTypes.modern;
             version = registryValue;
           }
      else
        if registryValue ? "git" && registryValue ? "ref"
        then { inherit pname;
               entryType = registryEntryTypes.remoteGit;
               version = null;
             }
        else
          if registryValue ? "repo"
             && registryValue ? "version"
             && registryValue ? "dependencies"
          then { inherit pname;
                 entryType = registryEntryTypes.legacy;
                 version =
                   builtins.substring 0 (builtins.stringLength registryValue.version) registryValue.version;
               }
          else
            throw
             "Could not determine the registry type of ${pname}.";

  # { entryType, pname, version } -> [{ entryType, pname, version, ...}]
  getModernRegistryEntryDirectDependencyArray = { entryType, pname, version, ...}:
    let
      registryIndexJson =
        lookupPackageInRegistryIndex { inherit pname version; };

      dependencyNamesArray =
        builtins.attrNames (registryIndexJson.dependencies);
    in
      builtins.map
        determineRegistryEntryTypeAndVersion
        dependencyNamesArray;

  # TODO
  # { entryType, pname } -> [{ entryType, pname, version }]
  getRemoteGitRegistryEntryDirectDependencyArray = entry:
    [ ];

  # { entryType, pname, git, ref } -> [{ entryType, pname, version }]
  getLegacyRegistryEntryDirectDependencyArray = { entryType, pname, ... }@entry:
    let
      dependencyNamesArray =
        entry.dependencies;
    in
      builtins.map
        determineRegistryEntryTypeAndVersion
        dependencyNamesArray;

  # { entryType, pname } -> [{ entryType, pname, version }]
  getRegistryEntryDependencyArray = { entryType, pname, ...}@entry:
    if entryType == registryEntryTypes.modern
    then getModernRegistryEntryDirectDependencyArray entry
    else
      if entryType == registryEntryTypes.remoteGit
      then getRemoteGitRegistryEntryDirectDependencyArray entry
      else
        if entryType == registryEntryTypes.legacy
        then getLegacyRegistryEntryDirectDependencyArray entry
        else
          throw
            "Entry type ${entryType} for package ${pname} is invalid.";



  lookupPackageInRegistryIndex = {pname, version}:
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

      in
        lib.lists.findSingle
          (json: json.version == version)
          (throw "No packages in registry index found for package ${pname}-${version}.")
          (throw "Multiple packages in registry index found for package ${pname}-${version}.")
          jsonArray;

  # Point-free - Takes two arguments attr: arr:
  buildDependencyAttr =
    builtins.foldl'
      (acc: cur:
        if builtins.hasAttr cur.pname acc
        then acc
        else
          let
            newDeps = getRegistryEntryDependencyArray cur;
          in
            buildDependencyAttr ({ ${cur.pname} = cur; } // acc) newDeps);

  spagoNixDirectDependencyNames =
    spagoYaml.package.dependencies;

  spagoNixDirectDependencyEntries = extraPackageNames:
    builtins.map
      determineRegistryEntryTypeAndVersion
      (extraPackageNames ++ spagoNixDirectDependencyNames);
in
{
  dependencyArray = { extraPackageNames ? []}:
    buildDependencyAttr {} (spagoNixDirectDependencyEntries extraPackageNames);
}
