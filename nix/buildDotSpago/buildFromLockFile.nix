{ fromYAML, mkDerivation, registry }:
{ src, lockFileNix }:
let

  psciSupport = {
    "psci-support" = {
      type =
        "registry";

      version =
        "6.0.0";

      integrity =
        let
          psciJSON =
            builtins.fromJSON (builtins.readFile "${registry}/metadata/psci-support.json");

          integrity =
            psciJSON.published."6.0.0".hash;
        in
        integrity;
    };
  };

  packages =
    if (lockFileNix.packages ? "psci-support")
    then
      lockFileNix.packages
    else lockFileNix.packages // psciSupport;

  buildDerivationFromRegistry = pname: package:
    let
      integrity =
        package.integrity;

      version =
        package.version;

      remoteSrc =
        builtins.fetchurl {
          url = "https://packages.registry.purescript.org/${pname}/${version}.tar.gz";
          sha256 = integrity;
        };

    in
      { pathString = "${pname}-${version}";
        packageDerivation = mkDerivation {
          inherit pname version;
          src =
            remoteSrc;

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

      remoteSrc =
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
            name =
              pname;

            src =
              remoteSrc;

            installPhase =
              ''
              mkdir $out
              cp -r ${subdir} $out
              '';
          };
      };

  buildDerivationFromLocalPath =
    pname: package:
    let
      path =
        package.path;

    in
      mkDerivation {
        name =
          pname;

        src = "${src}/${path}";

        installPhase =
          ''
          mkdir $out;
          cp -r * $out
          '';
      };



  buildDerivation = pname: package:
    if package.type == "registry"
    then buildDerivationFromRegistry pname package
    else
      if package.type == "git"
      then buildDerivationFromGit pname package
      else
        if package.type == "local"
        then buildDerivationFromLocalPath pname package
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
