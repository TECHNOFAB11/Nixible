{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) types mkOption;

  collectionType = types.submodule {
    options = {
      version = mkOption {
        type = types.str;
        description = "Version of collection";
      };
      hash = mkOption {
        type = types.str;
        description = "Hash of the collection tarball";
      };
    };
  };
in {
  options = {
    ansiblePackage = mkOption {
      type = types.package;
      default = pkgs.python3Packages.callPackage ./ansible-core.nix {};
      description = "Ansible package to use (default doesn't have any collections installed for size)";
    };
    collections = mkOption {
      type = types.attrsOf collectionType;
      default = {};
      description = "Collections to fetch and install";
    };
    dependencies = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "List of packages to include at runtime";
    };
    playbook = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "Name of the play";
          };
          hosts = mkOption {
            type = types.str;
            description = "The target hosts for this play (e.g., 'all', 'webservers')";
          };
          become = mkOption {
            type = types.bool;
            default = false;
            description = "Whether to use privilege escalation (become: yes)";
          };
          tasks = mkOption {
            type = types.listOf types.attrs;
            default = [];
            description = "List of tasks to execute in this play";
          };
        };
      });
      description = "The actual playbook, defined as a Nix data structure";
    };

    inventory = mkOption {
      type = types.attrs;
      default = {};
      description = "Ansible inventory, will be converted to json and passed to ansible";
    };

    inventoryFile = mkOption {
      internal = true;
      type = types.package;
    };
    playbookFile = mkOption {
      internal = true;
      type = types.package;
    };
    installedCollections = mkOption {
      internal = true;
      type = types.package;
    };
    cli = mkOption {
      internal = true;
      type = types.package;
    };
  };
  config = {
    inventoryFile = (pkgs.formats.json {}).generate "inventory.json" config.inventory;
    playbookFile = (pkgs.formats.yaml {}).generate "playbook.yml" config.playbook;
    installedCollections = pkgs.callPackage ./ansible-collections.nix {} config.ansiblePackage config.collections;
    cli = pkgs.writeShellApplication {
      name = "nixible";
      runtimeInputs = config.dependencies;
      text = ''
        set -euo pipefail
        export ANSIBLE_COLLECTIONS_PATH=${config.installedCollections}

        git_repo=$(git rev-parse --show-toplevel 2>/dev/null || true)
        ${config.ansiblePackage}/bin/ansible-playbook -i ${config.inventoryFile} ${config.playbookFile} -e "pwd=$(pwd)" -e "git_root=$git_repo" "$@"
      '';
    };
  };
}
