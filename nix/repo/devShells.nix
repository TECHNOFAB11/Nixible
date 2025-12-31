{
  inputs,
  cell,
  ...
}: let
  inherit (inputs) pkgs devshell treefmt devtools-lib;
  inherit (cell) soonix;
  treefmtWrapper = treefmt.mkWrapper pkgs {
    projectRootFile = "flake.nix";
    programs = {
      alejandra.enable = true;
      mdformat.enable = true;
    };
    settings.formatter.mdformat.command = let
      pkg = pkgs.python3.withPackages (p: [
        p.mdformat
        p.mdformat-mkdocs
      ]);
    in "${pkg}/bin/mdformat";
  };
in {
  default = devshell.mkShell {
    imports = [soonix.devshellModule devtools-lib.devshellModule];
    packages = [
      treefmtWrapper
    ];
    lefthook.config = {
      "pre-commit" = {
        parallel = true;
        jobs = [
          {
            name = "treefmt";
            stage_fixed = true;
            run = "${treefmtWrapper}/bin/treefmt";
            env.TERM = "dumb";
          }
          {
            name = "soonix";
            stage_fixed = true;
            run = "nix run .#soonix:update";
          }
        ];
      };
    };
  };
}
