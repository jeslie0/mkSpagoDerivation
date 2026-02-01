{ mkSpagoDerivation, purs, spago, esbuild }:
let
  # To make nix cache the output directory, make a derivation that
  # only depends on the spago yaml and spago lock files.
  dependenciesCache =
    mkSpagoDerivation {
      spagoYaml = ./spago.yaml;
      spagoLock = ./spago.lock;
      src =
      builtins.filterSource
        (path: type: baseNameOf path == "spago.yaml" || baseNameOf path == "spago.lock")
        ./.;
      # Could also use the numtime's nix-filter:
      #
      # src =
      #   nix-filter {
      #     root =
      #       "${self}/software/web";

      #     include =
      #       ["spago.yaml" "spago.lock"];
      #   };
      nativeBuildInputs = [ purs spago esbuild ];
      name = "spago-dependencies";
      version = "0.1.0";
      buildPhase = "spago install";
      installPhase = ''
                   mkdir $out
                   mv output $out
                   cp -r .spago $out
                   '';
    };
in
# Copy the .spago and output directories from the dependenciesCache
# into the source directory. Spago will then not rebuild the dependencies.
mkSpagoDerivation {
  spagoYaml = ./spago.yaml;
  spagoLock = ./spago.lock;
  nativeBuildInputs = [ purs spago esbuild ];
  name = "spago-cache-test";
  version = "0.1.0";
  src = ./.;
  buildPhase = ''
             cp -r ${dependenciesCache}/* .
             chmod -R 0755 ./output
             spago build
             '';
  installPhase = ''
               mkdir $out
               cp -r * $out
               '';
}
