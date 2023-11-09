{ fromYAML, mkDerivation }:
lockFileNix:
let
  packages =
    lockFileNix.packages;

  buildDerivationFromRegistry = pname: package:
    let
      integrity =
        package.integrity;

      version =
        package.version;

      src =
        builtins.fetchurl {
          url = "https://packages.registry.purescript.org/${pname}/${version}.tar.gz";
          sha256 = integrity;
        };

    in
      { pathString = "${pname}-${version}";
        packageDerivation = mkDerivation {
          inherit pname version src;
          installPhase =
            "mkdir $out; cp -r * $out";
        };
      };

  buildDerivationFromGit = pname: package:
    let
      url =
        package.url;

      rev =
        package.rev;

      src =
        builtins.fetchGit {
          inherit url rev;
          name = pname;
        };

      subdir =
        if package ? "subdir"
        then "${package.subdir}/*"
        else "*";
    in
      { pathString = "${pname}/${rev}";
        packageDerivation =
          mkDerivation {
            inherit src;
            name = pname;
            installPhase =
              ''
              mkdir $out
              cp -r ${subdir} $out
              '';
          };
      };

  buildDerivation = pname: package:
    if package.type == "registry"
    then buildDerivationFromRegistry pname package
    else
      if package.type == "git"
      then buildDerivationFromGit pname package
      else
        throw
          "Unable to determine package type ${package.type}.";

  derivationList =
    builtins.attrValues (
    builtins.mapAttrs
      buildDerivation
      packages
    );

in
derivationList
