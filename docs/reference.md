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

## Configuration Options

### `ansiblePackage`

**Type:** `package`
**Default:** Custom ansible-core package

The Ansible package to use. The default package is optimized for size, by not
including the gazillion collections that `pkgs.ansible` and `pkgs.ansible-core` include.

```nix
ansiblePackage = pkgs.ansible;
```

### `collections`

**Type:** `attrsOf collectionType`
**Default:** `{}`

Ansible collections to fetch from Galaxy.

```nix
collections = {
  "community-general" = {
    version = "8.0.0";
    hash = "sha256-...";
  };
};
```

### `dependencies`

**Type:** `listOf package`
**Default:** `[]`

Additional packages available at runtime.

```nix
dependencies = [pkgs.git pkgs.rsync];
```

### `inventory`

**Type:** `attrs`
**Default:** `{}`

Ansible inventory as Nix data structure, converted to JSON.

```nix
inventory = {
  webservers = {
    hosts = {
      web1 = { ansible_host = "192.168.1.10"; };
    };
    vars = {
      http_port = 80;
    };
  };
};
```

### `playbook`

**Type:** `listOf playbookType`

List of plays that make up the playbook.

```nix
playbook = [
  {
    name = "Configure servers";
    hosts = "webservers";
    become = true;
    tasks = [
      {
        name = "Install nginx";
        package = {
          name = "nginx";
          state = "present";
        };
      }
    ];
  }
];
```

## Collection Type

### `version`

**Type:** `str`

Version of the collection from Ansible Galaxy.

### `hash`

**Type:** `str`

SHA256 hash of the collection tarball for verification.

## Playbook Type

### `name`

**Type:** `str`

Name of the play.

### `hosts`

**Type:** `str`

Target hosts pattern (e.g., "all", "webservers", "localhost").

### `become`

**Type:** `bool`
**Default:** `false`

Whether to use privilege escalation.

### `tasks`

**Type:** `listOf attrs`
**Default:** `[]`

List of tasks to execute. Each task corresponds to Ansible task syntax.

Standard Ansible playbook options are supported: `gather_facts`, `serial`, `vars`, `vars_files`, `tags`, `handlers`, `pre_tasks`, `post_tasks`, etc.
