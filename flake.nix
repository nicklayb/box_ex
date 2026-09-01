{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        beamPackages = (
          elixir:
          [
            elixir
          ]
          ++ (with pkgs.beam27Packages; [
            erlang
            expert
          ])
        );
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs =
            with pkgs;
            [
              inotify-tools
              nodejs_22
            ]
            ++ beamPackages pkgs.beam27Packages.elixir_1_18;

          shellHook = ''
            export MIX_HOME=$PWD/.nix-mix
            export HEX_HOME=$PWD/.nix-hex
            mix deps.get
          '';
        };
      }
    );
}
