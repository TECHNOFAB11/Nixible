# Usage

Learn how to build and use Nixible configurations.

## Using flakeModule

The recommended way to use Nixible is with the flakeModule:

```nix title="flake.nix"
{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixible.url = "gitlab:TECHNOFAB/nixible?dir=lib";
  };
  
  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ nixible.flakeModule ];
      systems = # ...

      perSystem = { pkgs, ... }: {
        nixible = {
          deploy = {
            dependencies = [ pkgs.rsync ];
            inventory = {
              webservers = {
                hosts = {
                  web1 = { ansible_host = "192.168.1.10"; };
                };
              };
            };
            playbook = [{
              name = "Deploy application";
              hosts = "webservers";
              tasks = [{
                name = "Deploy files";
                copy = {
                  src = "{{ pwd }}/dist/";
                  dest = "/var/www/";
                };
              }];
            }];
          };
        };
      };
    };
    };
  };
}
```

Then run with:

```bash
nix run .#nixible:deploy

# With ansible-playbook options
nix run .#nixible:deploy -- --check --diff --limit web1
```

## Using the CLI directly

You can also create CLI packages directly:

```nix title="flake.nix"
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixible.url = "gitlab:TECHNOFAB/nixible?dir=lib";
  };
  
  outputs = { nixpkgs, nixible, ... }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    lib = nixpkgs.lib;
    nixible_lib = nixible.lib { inherit pkgs lib; };
  in {
    packages.x86_64-linux.deploy = nixible_lib.mkNixibleCli ./deploy.nix;
  };
}
```

Then run with:

```bash
nix run .#deploy

# Dry run with diff
nix run .#deploy -- --check --diff

# Limit to specific hosts
nix run .#deploy -- --limit webservers

# Extra variables
nix run .#deploy -- --extra-vars "env=production debug=true"
# etc.
```

## Variables

Nixible automatically provides these variables to your playbooks:

- `pwd`: Current working directory when nixible is run
- `git_root`: Git repository root (empty if not in a git repo)

Use them in your playbooks:

```nix
playbook = [{
  name = "Deploy from current directory";
  hosts = "localhost";
  tasks = [{
    name = "Copy files";
    copy = {
      src = "{{ pwd }}/dist/";
      dest = "/var/www/";
    };
  }];
}];
```
