{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flakelight = {
      url = "github:nix-community/flakelight";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix2tree-sitter = {
      url = "github:0komo/nix2tree-sitter";
      inputs = {
        flakelight.follows = "flakelight";
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = { self, flakelight, nix2tree-sitter, ... }@inputs:
    flakelight ./. ({ lib, ... }: {
      inherit inputs;
      devShell = {
        stdenv = lib.mkForce (pkgs: pkgs.stdenv);
        packages = pkgs: with pkgs; [
          nix
          tree-sitter
          nodejs_20
        ];
        env = pkgs: {
          TREE_SITTER_JS_RUNTIME = lib.getExe pkgs.nodejs_20;
        };
      };

      outputs.tree-sitter-grammar = import ./grammar.nix nix2tree-sitter.lib;
    });
}
