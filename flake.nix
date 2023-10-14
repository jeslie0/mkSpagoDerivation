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
        import ./nix/fromYAML.nix {
          stdenv = prev.stdenv;
          yaml2json = prev.yaml2json;
        };

      buildDotSpagoBuilder = prev:
        import ./nix/buildDotSpago.nix {
          inherit registry registry-index;
          stdenv = prev.stdenv;
          lib = prev.lib;
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

          buildDotSpago = final: prev: {
            buildDotSpago = buildDotSpagoBuilder prev;
          };

          buildSpagoNodeJs = final: prev: {
            buildSpagoNodeJs = buildSpagoNodeJsBuilder prev;
          };

          mkSpagoDerivation = final: prev: {
            mkSpagoDerivation = mkSpagoDerivationBuilder prev final;
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
          }
      );

}
