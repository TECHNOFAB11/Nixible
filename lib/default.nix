{
  pkgs,
  lib ? pkgs.lib,
  ...
}: let
  inherit (lib) evalModules;
in rec {
  module = ./module.nix;

  mkNixible = config:
    evalModules {
      specialArgs = {inherit pkgs;};
      modules = [
        module
        config
      ];
    };

  mkNixibleCli = config: (mkNixible config).config.cli;
}
