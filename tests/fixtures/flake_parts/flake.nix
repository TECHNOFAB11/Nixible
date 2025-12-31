{
  outputs = {
    flake-parts,
    systems,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        "@repo_path@/lib/flakeModule.nix"
      ];
      systems = import systems;
      flake = {};
      perSystem = _: {
        nixible = {
          "hello".playbook = [
            {
              name = "Hello World";
              hosts = "localhost";
              tasks = [
                {
                  name = "Say hello";
                  debug.msg = "Hello from Nixible!";
                }
              ];
            }
          ];
          "test".playbook = [];
        };
      };
    };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default-linux";
  };
}
