{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    registry = {
      url = "github:purescript/registry";
      flake = false;
    };
    registry-index = {
      url = "github:purescript/registry-index";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, registry, registry-index }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let pkgs =
            nixpkgs.legacyPackages.${system};

          fromYaml =
            import ./from-yaml.nix { yaml2json = pkgs.yaml2json; stdenv = pkgs.stdenv; };

          buildDotSpago =
            (import ./lib.nix {inherit registry registry-index fromYaml; stdenv = pkgs.stdenv;  spagoDotYaml = builtins.readFile ./spago.yaml; }).buildSpagoNodeJs;
      in
        {

          packages.hello = buildDotSpago;

          defaultPackage = self.packages.${system}.hello;

          devShell = pkgs.mkShell {
            inputsFrom = [ ]; # Include build inputs from packages in
            # this list
            packages = [ ]; # Extra packages to go in the shell
          };
      }
    );

}
