{ mkDerivation, fromYAML, name, url, ref, subdir }:
let
  src =
    builtins.fetchGit {
      inherit url ref;
    };

  packageSpagoYamlPath =
    "${src}/${subdir}/spago.yaml";

  packageSpagoNix =
    fromYAML (builtins.readFile packageSpagoYamlPath);

  packageDependencies =
    if packageSpagoNix.package ? "dependencies"
    then packageSpagoNix.package.dependencies
    else [];

  packageExtraDependencies =
    if packageSpagoNix.workspace ? "extra_packages"
    then packageSpagoNix.workspace.extra_packages
    else {};

  package =
    mkDerivation {
    inherit name src;

    installPhase =
        "mkdir $out; cd ${subdir}; cp -r * $out";
    };

  output =
    builtins.tryEval { inherit package packageDependencies packageExtraDependencies; };
in
if output.success
then
  output.value
else
  throw
    "Could build package ${packageSpagoNix.package.name}"
