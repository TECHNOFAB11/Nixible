{
  pkgs,
  nblib,
  ntlib,
  ...
}: {
  suites."Lib Tests" = {
    pos = __curPos;
    tests = [
      {
        name = "mkNixibleCli generates executable";
        type = "script";
        script = let
          config = {
            playbook = [
              {
                name = "Test CLI";
                hosts = "localhost";
                tasks = [
                  {
                    debug.msg = "Testing CLI generation";
                  }
                ];
              }
            ];
          };
          cli = nblib.mkNixibleCli config;
        in
          # sh
          ''
            ${ntlib.helpers.path [pkgs.gnugrep]}
            ${ntlib.helpers.scriptHelpers}

            # Check CLI contains expected content
            assert_file_contains "${cli}/bin/nixible" "ansible-playbook" "should contain ansible-playbook command"
            assert_file_contains "${cli}/bin/nixible" "ANSIBLE_COLLECTIONS_PATH" "should set collections path"
          '';
      }
      {
        name = "inventory JSON generation";
        type = "script";
        script = let
          config = {
            inventory = {
              webservers = {
                hosts = {
                  web1 = {ansible_host = "192.168.1.10";};
                  web2 = {ansible_host = "192.168.1.11";};
                };
                vars = {
                  http_port = 80;
                };
              };
            };
            playbook = [
              {
                name = "Test inventory";
                hosts = "webservers";
                tasks = [];
              }
            ];
          };
          result = nblib.mkNixible config;
          inventoryFile = result.config.inventoryFile;
        in
          # sh
          ''
            ${ntlib.helpers.path [pkgs.jq pkgs.gnugrep]}
            ${ntlib.helpers.scriptHelpers}

            # Check inventory file exists
            assert "-f ${inventoryFile}" "inventory file should exist"

            # Check JSON structure
            jq -e '.webservers.hosts.web1.ansible_host' "${inventoryFile}" | grep -q "192.168.1.10"
            assert_eq $? 0 "should contain web1 host"

            jq -e '.webservers.vars.http_port' "${inventoryFile}" | grep -q "80"
            assert_eq $? 0 "should contain http_port variable"
          '';
      }

      {
        name = "playbook YAML generation";
        type = "script";
        script = let
          config = {
            playbook = [
              {
                name = "Test playbook generation";
                hosts = "localhost";
                become = true;
                tasks = [
                  {
                    name = "Install package";
                    package = {
                      name = "nginx";
                      state = "present";
                    };
                  }
                  {
                    name = "Start service";
                    service = {
                      name = "nginx";
                      state = "started";
                    };
                  }
                ];
              }
            ];
          };
          result = nblib.mkNixible config;
          playbookFile = result.config.playbookFile;
        in
          # sh
          ''
            ${ntlib.helpers.path [pkgs.gnugrep]}
            ${ntlib.helpers.scriptHelpers}

            # Check playbook file exists
            assert "-f ${playbookFile}" "playbook file should exist"

            # Check YAML structure
            assert_file_contains "${playbookFile}" "Test playbook generation" "should contain play name"
            assert_file_contains "${playbookFile}" "become: true" "should have become enabled"
            assert_file_contains "${playbookFile}" "Install package" "should contain first task"
            assert_file_contains "${playbookFile}" "nginx" "should contain nginx package"
          '';
      }
      {
        name = "ansible package is configurable";
        type = "script";
        script = let
          config = {pkgs, ...}: {
            ansiblePackage = pkgs.python3Packages.ansible;
            playbook = [
              {
                name = "Test custom ansible";
                hosts = "localhost";
                tasks = [];
              }
            ];
          };
          cli = nblib.mkNixibleCli config;
        in
          # sh
          ''
            ${ntlib.helpers.path [pkgs.gnugrep]}
            ${ntlib.helpers.scriptHelpers}

            # check that custom ansible package is used
            assert_file_contains "${cli}/bin/nixible" "${pkgs.python3Packages.ansible}" "should use custom ansible package"
          '';
      }
      {
        name = "installed collections directory";
        type = "script";
        script = let
          config = {
            collections = {
              "amazon-aws" = {
                version = "10.1.0";
                hash = "sha256-w1wv0lYnuHXrpNubvePwKag4oM1k1I43HreFWYeIWgU=";
              };
              "community-aws" = {
                version = "10.0.0";
                hash = "sha256-oqsfmuztf8FLalwSDvRYcuvOVzLbWx/cEsYoUt8Dbn0=";
              };
            };
          };
          result = nblib.mkNixible config;
          collections = result.config.installedCollections;
        in
          # sh
          ''
            ${ntlib.helpers.scriptHelpers}

            assert "-d ${collections}" "collections directory should exist"
            assert "-d ${collections}/ansible_collections/amazon/aws" "amazon/aws directory should exist"
            assert "-d ${collections}/ansible_collections/community/aws" "community/aws directory should exist"
          '';
      }
    ];
  };
}
