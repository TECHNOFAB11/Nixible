{
  flake-parts-lib,
  lib,
  ...
}: let
  inherit (lib) mkOption types;
in {
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    {
      config,
      pkgs,
      ...
    }: let
      nixible-lib = import ./. {inherit pkgs lib;};
    in {
      options.nixible = mkOption {
        type = types.attrsOf (types.submodule (args:
          # needed to get pkgs in there, weirdly enough
            import nixible-lib.module (args
              // {
                inherit pkgs;
              })));
        default = {};
      };

      config.legacyPackages = lib.fold (playbook: acc: acc // playbook) {} (
        map (playbook_name: {
          "nixible:${playbook_name}" = (builtins.getAttr playbook_name config.nixible).cli;
        }) (builtins.attrNames config.nixible)
      );
    }
  );
}
