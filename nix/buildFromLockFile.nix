{ fromYAML, mkDerivation, registry, lib }:
{ src, spagoLockFile }:
let
  lockFileNix =
    fromYAML (builtins.readFile spagoLockFile);

  packageSet =
    lockFileNix.packages;

  # { localPackages, registryPackages, gitPackages }
  formattedPackageSet =
    let
      packageNames =
        builtins.attrNames packageSet;
    in
      builtins.foldl'
        (
          prev: cur:
          prev //
          ( if packageSet.${cur}.type == "local"
            then
              { localPackages =
                  prev.localPackages // {
                    ${cur} = {
                      name = cur;
                    } // packageSet.${cur};
                  };
              }
            else
              if packageSet.${cur}.type == "registry"
              then
                { registryPackages =
                    prev.registryPackages // {
                      ${cur} = {
                        name = cur;
                      } // packageSet.${cur};
                    };
                }
              else
                if packageSet.${cur}.type == "git"
                then
                  { gitPackages =
                      prev.gitPackages // {
                        ${cur} = {
                          name = cur;
                        } // packageSet.${cur};
                      };
                  }
                else
                  throw "Package ${cur} has nonstandard type: ${packageSet.${cur}.type}."
          )
        )
        { localPackages = {}; registryPackages = {}; gitPackages = {}; }
        packageNames;


  buildDerivationFromGit = package:
    let
      name =
        package.name;

      url =
        package.url;

      rev =
        package.rev;

      remoteSrc =
        builtins.fetchGit {
          inherit url rev name;
        };

      subdir =
        if package ? "subdir"
        then "${package.subdir}/*"
        else "*";
    in
      {
        pathString =
          "${name}/${rev}";

        packageDerivation =
          mkDerivation {
            inherit name;

            src =
              remoteSrc;

            installPhase =
              ''
              mkdir $out
              cp -r ${subdir} $out
              '';
          };
      };

  gitPackageBuildString = package:
    let
      packageDerivationInfo =
        buildDerivationFromGit package;

      packageDerivation =
        packageDerivationInfo.packageDerivation;

      packagePath =
        packageDerivationInfo.pathString;
    in
      ''
        mkdir -p .spago/packages/${packagePath}
        cp -r ${packageDerivation}/* .spago/packages/${packagePath};
      '';

  buildDerivationFromRegistry = package:
    let
      integrity =
        package.integrity;

      version =
        package.version;

      remoteSrc =
        builtins.fetchurl {
          url = "https://packages.registry.purescript.org/${package.name}/${version}.tar.gz";
          sha256 = integrity;
        };
    in
      {
        pathString =
          "${package.name}-${version}";

        packageDerivation =
          mkDerivation {
            inherit version;

            pname =
              package.name;

            src =
              remoteSrc;

            installPhase =
              "mkdir $out; cp -r * $out";
        };
      };

  registryPackageBuildString = package:
    let
      packageDerivationInfo =
        buildDerivationFromRegistry package;

      packageDerivation =
        packageDerivationInfo.packageDerivation;

      packagePath =
        packageDerivationInfo.pathString;
    in
      ''
        mkdir -p .spago/packages/${packagePath}
        cp -r ${packageDerivation}/* .spago/packages/${packagePath};
      '';


  localPackageBuildString = package:
    "";

  registryPackageCommand =
    lib.concatMapStrings
      registryPackageBuildString
      (builtins.attrValues formattedPackageSet.registryPackages);

  gitPackageCommand =
    lib.concatMapStrings
      gitPackageBuildString
      (builtins.attrValues formattedPackageSet.gitPackages);

  localPackageCommand =
    lib.concatMapStrings
      localPackageBuildString
      (builtins.attrValues formattedPackageSet.localPackages);
in
builtins.concatStringsSep "\n" [registryPackageCommand gitPackageCommand localPackageCommand]
