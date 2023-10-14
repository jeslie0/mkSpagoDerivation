{
  description = "A very basic flake";

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
    flake-utils.lib.eachDefaultSystem (
      system:
      let pkgs =
            import nixpkgs {
              inherit system;
              overlays = [ ps-overlay.overlays.default ];
            };

          stdenv =
            pkgs.stdenv;

          lib =
            pkgs.lib;

          fromYAML =
            import ./fromYAML.nix { inherit stdenv; yaml2json = pkgs.yaml2json; };

          buildDotSpago =
            import ./buildDotSpago.nix { inherit stdenv registry lib registry-index; };

          buildSpagoNodeJs =
            import ./buildSpagoNodeJs.nix { inherit stdenv registry registry-index; };
      in
        {
          mkSpagoDerivation =
            import ./mkSpagoDerivation.nix { inherit stdenv fromYAML buildDotSpago buildSpagoNodeJs registry registry-index; spago = pkgs.spago-unstable; purs = pkgs.purs; git = pkgs.git; };

      }
    );

}
