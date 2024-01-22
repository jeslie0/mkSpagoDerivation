{
  description = "A flake providing tools for building PureScript projects with Spago.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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

  outputs = { self, nixpkgs, ps-overlay, registry, registry-index }:
    let
      supportedSystems =
        [ "aarch64-linux" "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];

      forAllSystems =
        nixpkgs.lib.genAttrs supportedSystems;

      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [ ps-overlay.overlays.default ];
        });

      fromYAMLBuilder = prev:
        import "${ps-overlay}/nix/from-yaml.nix" { lib = prev.lib; };

      buildDotSpagoBuilder = prev:
        import ./nix/buildDotSpago.nix {
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
        import ./nix/mkSpagoDerivation.nix {
          inherit registry registry-index;
          buildSpagoNodeJs = buildSpagoNodeJsBuilder prev;
          fromYAML = fromYAMLBuilder prev;
          stdenv = prev.stdenv;
          git = prev.git;
          lib = prev.lib;
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

        checks = forAllSystems (system:
          let
            pkgs =
              nixpkgsFor.${system};
          in
          {
          registry =
            import ./tests/registry/registry.nix {
              mkSpagoDerivation = mkSpagoDerivationBuilder pkgs pkgs;
              esbuild = pkgs.esbuild;
              purs = pkgs.purs-unstable;
              spago = pkgs.spago-unstable;
            };

          registry-esbuild =
            import ./tests/registry-esbuild/registry-esbuild.nix {
              mkSpagoDerivation = mkSpagoDerivationBuilder pkgs pkgs;
              esbuild = pkgs.esbuild;
              purs-backend-es = pkgs.purs-backend-es;
              purs = pkgs.purs-unstable;
              spago = pkgs.spago-unstable;
            };

          monorepo =
            import ./tests/monorepo/monorepo.nix {
              mkSpagoDerivation = mkSpagoDerivationBuilder pkgs pkgs;
              esbuild = pkgs.esbuild;
              purs = pkgs.purs-unstable;
              spago = pkgs.spago-unstable;
            };

          remote-package =
            import ./tests/remote/remote.nix {
              mkSpagoDerivation = mkSpagoDerivationBuilder pkgs pkgs;
              esbuild = pkgs.esbuild;
              purs = pkgs.purs-unstable;
              spago = pkgs.spago-unstable;
            };

          local-package =
            import ./tests/local/local.nix {
              mkSpagoDerivation = mkSpagoDerivationBuilder pkgs pkgs;
              esbuild = pkgs.esbuild;
              purs = pkgs.purs-unstable;
              spago = pkgs.spago-unstable;
            };
          }
        );
      };
}
