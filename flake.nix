{
  description = "A flake providing tools for building purescript projects with spago.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    ps-overlay.url = "github:thomashoneyman/purescript-overlay";
    registry = {
      url = "github:purescript/registry";
      flake = false;
    };
    registry-index = {
      url = "github:purescript/registry-index";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, ps-overlay, registry, registry-index }:
    let
      fromYAMLBuilder = prev:
        import "${ps-overlay}/nix/from-yaml.nix" { lib = prev.lib; };

      buildDotSpagoBuilder = prev:
        import ./nix/buildDotSpago/buildDotSpago.nix {
          inherit self registry registry-index;
          mkDerivation = prev.stdenv.mkDerivation;
          lib = prev.lib;
          fromYAML = fromYAMLBuilder prev;
        };

      buildSpagoNodeJsBuilder = prev:
        import ./nix/buildSpagoNodeJs.nix {
          inherit registry registry-index;
          stdenv = prev.stdenv;
        };

      mkSpagoDerivationBuilder = final: prev:
        let
          overlayedPkgs =
            ps-overlay.overlays.default final prev;

          spago =
            overlayedPkgs.spago-unstable;

          purs =
            overlayedPkgs.purs;
        in
          import ./nix/mkSpagoDerivation.nix {
            inherit registry registry-index spago purs;
            buildDotSpago = buildDotSpagoBuilder prev;
            buildSpagoNodeJs = buildSpagoNodeJsBuilder prev;
            fromYAML = fromYAMLBuilder prev;
            stdenv = prev.stdenv;
            git = prev.git;
          };
    in
      {
        overlays = {
          default = final: prev:
            prev.lib.composeManyExtensions
              (builtins.attrValues (builtins.removeAttrs self.overlays ["default"])) final prev;

          # Function that returns a derivation outputting the .spago
          # directory needed for the given project.
          buildDotSpago = final: prev: {
            buildDotSpago = buildDotSpagoBuilder prev;
          };

          # Function that returns a derivation outputting the spago-nodejs
          # directory needed for the given project.
          buildSpagoNodeJs = final: prev: {
            buildSpagoNodeJs = buildSpagoNodeJsBuilder prev;
          };

          # Function that takes a spago.yaml or a spago.lock file and
          # builds the project here.
          mkSpagoDerivation = final: prev: {
            mkSpagoDerivation = mkSpagoDerivationBuilder prev final;
          };

          fromYAML = final: prev: {
            fromYAML = fromYAMLBuilder prev;
          };
        };
      }
      // flake-utils.lib.eachDefaultSystem (
        system:
        let pkgs =
              import nixpkgs {
                inherit system;
                overlays = [ ps-overlay.overlays.default ];
              };
        in
          {
            buildDotSpago =
              buildDotSpagoBuilder pkgs;

            buildSpagoNodeJs =
              buildSpagoNodeJsBuilder pkgs;

            mkSpagoDerivation =
              mkSpagoDerivationBuilder pkgs pkgs;

            fromYAML =
              fromYAMLBuilder pkgs;

            checks = {
              registry =
                import ./tests/registry/registry.nix {
                  mkSpagoDerivation = mkSpagoDerivationBuilder pkgs pkgs;
                };

              registry-esbuild =
                import ./tests/registry-esbuild/registry-esbuild.nix {
                  mkSpagoDerivation = mkSpagoDerivationBuilder pkgs pkgs;
                  esbuild = pkgs.esbuild;
                  purs-backend-es = pkgs.purs-backend-es;
                  purs-unstable = pkgs.purs-unstable;
                };

              monorepo =
                import ./tests/monorepo/monorepo.nix {
                  mkSpagoDerivation = mkSpagoDerivationBuilder pkgs pkgs;
                };
            };

          }
      );
}
