# Reference

## `flakeModule`

The `flakeModule` for [flake-parts](https://flake.parts).

Provides a `perSystem.nixible` option for defining Nixible configurations directly in your flake.

```nix
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
          "deploy" = {
            dependencies = [ pkgs.rsync ];
            playbook = [{
              name = "Deploy application";
              hosts = "servers";
              tasks = [ /* ... */ ];
            }];
          };
          "backup" = {
            dependencies = [ pkgs.borg ];
            playbook = [{
              name = "Backup data";
              hosts = "backup_servers";
              tasks = [ /* ... */ ];
            }];
          };
        };
      };
    };
}
```

Each configuration defined in `perSystem.nixible` automatically creates a corresponding package in `legacyPackages` with the name `nixible:<config-name>`. These packages contain the CLI executable for that specific configuration.

**Example usage:**

```bash
nix run .#nixible:deploy
nix run .#nixible:backup
```

## `lib`

### `module`

The nix module for validation of Nixible configurations.
Used internally by `mkNixible`.

### `mkNixible`

```nix
mkNixible config
```

Creates a Nixible configuration module evaluation.
`config` can be a path to a nix file or a function/attrset.

**Noteworthy attributes**:

- `config`: The evaluated configuration with all options
- `config.inventoryFile`: Generated JSON inventory file
- `config.playbookFile`: Generated YAML playbook file
- `config.installedCollections`: Directory containing installed collections
- `config.cli`: The nixible CLI executable

### `mkNixibleCli`

```nix
mkNixibleCli config
```

Creates a CLI executable for your Nixible configuration.
Basically `(mkNixible config).config.cli`.

______________________________________________________________________

See [options](./options.md) for more.
