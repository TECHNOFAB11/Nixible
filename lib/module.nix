{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) mkOptionType isType filterAttrs types mkOption literalExpression;

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
  unsetOr = typ:
    (types.either unsetType typ)
    // {
      description = typ.description;
    };

  filterUnset = value:
    if builtins.isAttrs value && !builtins.hasAttr "_type" value
    then let
      filteredAttrs = builtins.mapAttrs (n: v: filterUnset v) value;
    in
      filterAttrs (name: value: (!isUnset value)) filteredAttrs
    else if builtins.isList value
    then builtins.filter (elem: !isUnset elem) (map filterUnset value)
    else value;

  mkUnsetOption = args:
    mkOption args
    // {
      type = unsetOr args.type;
      default = unset;
      defaultText = literalExpression "unset";
    };

  collectionType = types.submodule {
    options = {
      version = mkOption {
        type = types.str;
        description = ''
          Version of the collection.
        '';
        example = "1.0.0";
      };
      hash = mkOption {
        type = types.str;
        description = ''
          SHA256 hash of the collection tarball for verification.
        '';
        example = "sha256-...";
      };
    };
  };
  tasksType = types.submodule {
    freeformType = types.attrsOf (types.attrsOf types.anything);
    options = {
      name = mkUnsetOption {
        type = types.str;
        description = ''
          Name of the task.
        '';
      };
      register = mkUnsetOption {
        type = types.str;
        description = ''
          Register the task's output to a variable.
        '';
      };
      block = mkUnsetOption {
        type = types.listOf tasksType;
        description = ''
          A block of tasks to execute.
        '';
      };
      rescue = mkUnsetOption {
        type = types.listOf tasksType;
        description = ''
          A list of tasks to execute on failure of block tasks.
        '';
      };
      always = mkUnsetOption {
        type = types.listOf types.attrs;
        description = ''
          Tasks that always run, regardless of task status.
        '';
      };
      delegate_to = mkUnsetOption {
        type = types.str;
        description = ''
          Delegate task execution to another host.
        '';
      };
      ignore_errors = mkUnsetOption {
        type = types.bool;
        description = ''
          Ignore errors and continue with the playbook.
        '';
      };
      loop = mkUnsetOption {
        type = types.anything;
        description = ''
          Define a loop for the task.
        '';
      };
      when = mkUnsetOption {
        type = types.str;
        description = ''
          Condition under which the task runs.
        '';
      };
    };
  };
  playType = types.submodule {
    freeformType = types.attrsOf (types.attrsOf types.anything);
    options = {
      name = mkOption {
        type = types.str;
        description = ''
          Name of the play.
        '';
      };
      hosts = mkOption {
        type = types.str;
        description = ''
          The target hosts for this play (e.g., 'all', 'webservers').
        '';
        example = "all";
      };
      remote_user = mkUnsetOption {
        type = types.str;
        description = ''
          The user to execute tasks as on the remote server.
        '';
      };
      tags = mkUnsetOption {
        type = types.listOf types.str;
        description = ''
          Tags to filter tasks to run.
        '';
      };
      become = mkUnsetOption {
        type = types.bool;
        description = ''
          Whether to use privilege escalation (become: yes).
        '';
      };
      become_method = mkUnsetOption {
        type = types.str;
        description = ''
          Privilege escalation method.
        '';
      };
      vars = mkUnsetOption {
        type = types.attrs;
        description = ''
          Variables for the play.
        '';
      };
      gather_facts = mkUnsetOption {
        type = types.either types.bool types.str;
        description = ''
          Whether to run the setup module to gather facts before executing tasks.
        '';
      };
      when = mkUnsetOption {
        type = types.str;
        description = ''
          Condition under which the play runs.
        '';
      };
      tasks = mkOption {
        type = types.listOf tasksType;
        default = [];
        description = ''
          List of tasks to execute in this play
        '';
      };
    };
  };
  playbookType = types.listOf playType;
in {
  options = {
    ansiblePackage = mkOption {
      type = types.package;
      default = pkgs.python3Packages.callPackage ./ansible-core.nix {};
      description = ''
        The Ansible package to use. The default package is optimized for size, by not including the gazillion collections that pkgs.ansible and pkgs.ansible-core include.
      '';
      example = literalExpression "pkgs.ansible";
    };
    collections = mkOption {
      type = types.attrsOf collectionType;
      default = {};
      description = ''
        Ansible collections to fetch and install from Galaxy.
      '';
      example = {
        "community-general" = {
          version = "8.0.0";
          hash = "sha256-...";
        };
      };
    };
    dependencies = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "List of packages to include at runtime";
      example = literalExpression "[pkgs.git pkgs.rsync]";
    };
    playbook = mkOption {
      type = playbookType;
      apply = res: filterUnset res;
      description = "The actual playbook, defined as a Nix data structure";
      example = [
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
    };

    inventory = mkOption {
      type = types.attrs;
      default = {};
      description = ''
        Ansible inventory, will be converted to JSON and passed to Ansible.
      '';
      example = {
        webservers = {
          hosts = {
            web1 = {ansible_host = "192.168.1.10";};
          };
          vars = {
            http_port = 80;
          };
        };
      };
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
