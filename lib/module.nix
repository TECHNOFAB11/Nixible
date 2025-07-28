{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) mkOptionType isType filterAttrs types mkOption;

  unsetType = mkOptionType {
    name = "unset";
    description = "unset";
    descriptionClass = "noun";
    check = value: true;
  };
  unset = {
    _type = "unset";
  };
  isUnset = isType "unset";
  unsetOr = types.either unsetType;

  filterUnset = value:
    if builtins.isAttrs value && !builtins.hasAttr "_type" value
    then let
      filteredAttrs = builtins.mapAttrs (n: v: filterUnset v) value;
    in
      filterAttrs (name: value: (!isUnset value)) filteredAttrs
    else if builtins.isList value
    then builtins.filter (elem: !isUnset elem) (map filterUnset value)
    else value;

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
  tasksType = types.submodule {
    freeformType = types.attrsOf (types.attrsOf types.anything);
    options = {
      name = mkOption {
        type = unsetOr types.str;
        default = unset;
      };
      register = mkOption {
        type = unsetOr types.str;
        default = unset;
      };
      block = mkOption {
        type = unsetOr (types.listOf tasksType);
        default = unset;
      };
      always = mkOption {
        type = unsetOr (types.listOf types.attrs);
        default = unset;
      };
    };
  };
  playbookType = types.listOf (types.submodule {
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
        type = unsetOr types.bool;
        default = unset;
        description = "Whether to use privilege escalation (become: yes)";
      };
      gather_facts = mkOption {
        type = unsetOr types.bool;
        default = unset;
        description = "";
      };
      tasks = mkOption {
        type = types.listOf tasksType;
        default = [];
        description = "List of tasks to execute in this play";
      };
    };
  });
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
      type = playbookType;
      apply = res: filterUnset res;
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
