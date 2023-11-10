{ self, lib, fromYAML, mkDerivation, registry, registry-index }@env:

# This function takes a spagoNix set and builds the .spago directory
# as a derivation.
{ spagoYaml ? false
, lockFile ? false
, symlink ? true
, src
}:
let
  command =
    if symlink
    then "ln -s"
    else "cp -r";

  buildMethod =
    (import "${self}/nix/types").buildMethod;

  method =
    if
      spagoYaml && !lockFile

    then
      buildMethod.spago

    else
      if
        lockFile

      then
        buildMethod.lockFile

      else
        throw
          "Either a spagoYaml file or a lockFile must be provided.";

  spagoNix =
    fromYAML (builtins.readFile spagoYaml);

  lockFileNix =
    fromYAML (builtins.readFile lockFile);

  spagoDirectDeps =
    builtins.map
      (packageInfo:
        if
          builtins.isString packageInfo

        then
          packageInfo

        else
          builtins.head (builtins.attrNames packageInfo)
      )
      (["psci-support"] ++ spagoNix.package.dependencies);

  makePackageAndDepsFunc =
    import "${self}/nix/buildDotSpago/getRegistryDerivation.nix" env spagoNix;

  makeAllDependencies =
    builtins.foldl'
      (acc: cur:
        if
          builtins.hasAttr cur acc

        then
          acc

        else
          let
            newPackage =
              makePackageAndDepsFunc cur;
          in
            makeAllDependencies ({${cur} = newPackage.packageDerivation; } // acc) newPackage.dependencies
      );

  allDependencies =
    makeAllDependencies {} spagoDirectDeps;

  dependenciesCommandsList =
    builtins.map
      (package:
        let
          cleanedVersion =
            builtins.head (builtins.match "^v([0-9]*.[0-9]*.[0-9]*)$" package.version);
        in
        ''
mkdir -p .spago/packages/${package.pname}-${cleanedVersion}
${command} ${package}/* .spago/packages/${package.pname}-${cleanedVersion}
        ''
        )
      (builtins.attrValues allDependencies);

  lockFileCommandsList =
    builtins.map
      (package: ''
      mkdir -p .spago/packages/${package.pathString};
      ${command} ${package.packageDerivation}/* .spago/packages/${package.pathString};
       ''
      )
      (import "${self}/nix/buildDotSpago/buildFromLockFile.nix" { inherit fromYAML mkDerivation registry; } { inherit lockFileNix src; });

in
mkDerivation {
  name = "dot-spago";
  src = ./.;
  buildPhase =
    lib.concatStrings (
      if
        lockFile != false

      then
        lockFileCommandsList

      else
        dependenciesCommandsList
    );

  installPhase =
    ''
    mkdir $out;
    cp -r .spago $out;
    '';
}
