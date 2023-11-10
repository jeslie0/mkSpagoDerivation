{ self, lib, fromYAML, mkDerivation, registry, registry-index }@env:

# This function takes a spagoNix set and builds the .spago directory
# as a derivation.
{ spagoYaml ? false
, spagoLock ? false
, symlink ? true
, src
}:
let
  command =
    if symlink
    then "ln -s"
    else "cp -r";

  spagoNix =
    fromYAML (builtins.readFile spagoYaml);

  spagoLockNix =
    fromYAML (builtins.readFile spagoLock);

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

  spagoLockCommandsList =
    builtins.map
      (package: ''
      mkdir -p .spago/packages/${package.pathString};
      ${command} ${package.packageDerivation}/* .spago/packages/${package.pathString};
       ''
      )
      (import "${self}/nix/buildDotSpago/buildFromLockFile.nix" { inherit fromYAML mkDerivation registry; } { inherit spagoLockNix src; });

in
mkDerivation {
  name = "dot-spago";
  src = ./.;
  buildPhase =
    lib.concatStrings (
      if
        spagoLock != false

      then
        spagoLockCommandsList

      else
        dependenciesCommandsList
    );

  installPhase =
    ''
    mkdir $out;
    cp -r .spago $out;
    '';
}
