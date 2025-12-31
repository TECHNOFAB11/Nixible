{
  pkgs,
  nblib,
  ntlib,
  ...
}: {
  suites."Integration Tests" = {
    pos = __curPos;
    tests = [
      {
        name = "end-to-end configuration processing";
        type = "script";
        script = let
          config = {pkgs, ...}: {
            dependencies = [pkgs.curl];
            collections = {
              "community-general" = {
                version = "8.0.0";
                hash = "sha256-dNtdCxGj72LfMqPfzOpUSXLNLj1IkaAewRmHNizh67Q=";
              };
            };
            inventory = {
              test_group = {
                hosts = {
                  test1 = {ansible_host = "localhost";};
                };
                vars = {
                  test_var = "test_value";
                };
              };
            };
            playbook = [
              {
                name = "End-to-end test";
                hosts = "test_group";
                become = false;
                tasks = [
                  {
                    name = "Test task";
                    debug = {
                      msg = "Hello from {{ inventory_hostname }}";
                      var = "test_var";
                    };
                  }
                ];
              }
            ];
          };
          result = nblib.mkNixible config;
          cli = nblib.mkNixibleCli config;
        in
          # sh
          ''
            ${ntlib.helpers.path [pkgs.jq pkgs.gnugrep]}
            ${ntlib.helpers.scriptHelpers}

            # test that all components are generated
            assert "-f ${result.config.inventoryFile}" "should generate inventory file"
            assert "-f ${result.config.playbookFile}" "should generate playbook file"
            assert "-d ${result.config.installedCollections}" "should create collections directory"
            assert "-x ${cli}/bin/nixible" "should create CLI executable"

            # test inventory content
            jq -e '.test_group.hosts.test1.ansible_host' "${result.config.inventoryFile}" | grep -q "localhost"
            assert_eq $? 0 "inventory should contain test host"

            jq -e '.test_group.vars.test_var' "${result.config.inventoryFile}" | grep -q "test_value"
            assert_eq $? 0 "inventory should contain test variable"

            # test playbook content
            assert_file_contains "${result.config.playbookFile}" "End-to-end test" "playbook should contain play name"
            assert_file_contains "${result.config.playbookFile}" "test_group" "playbook should target test_group"
            assert_file_contains "${result.config.playbookFile}" "Hello from" "playbook should contain debug message"
          '';
      }
      {
        name = "SOPS example configuration";
        type = "script";
        script = let
          # use the actual SOPS example from the repo
          sopsConfig = ../examples/sops.nix;
          result = nblib.mkNixible sopsConfig;
          cli = nblib.mkNixibleCli sopsConfig;
        in
          # sh
          ''
            ${ntlib.helpers.path [pkgs.gnugrep]}
            ${ntlib.helpers.scriptHelpers}

            assert "-f ${result.config.inventoryFile}" "SOPS example should generate inventory"
            assert "-f ${result.config.playbookFile}" "SOPS example should generate playbook"
            assert "-x ${cli}/bin/nixible" "SOPS example should generate CLI"

            # test SOPS-specific content
            assert_file_contains "${result.config.playbookFile}" "community.crypto.openssl_privatekey_pipe" "should use crypto collection"
            assert_file_contains "${result.config.playbookFile}" "community.sops.sops_encrypt" "should use sops collection"
            assert_file_contains "${result.config.playbookFile}" "no_log: true" "should have no_log for security"
          '';
      }
    ];
  };
}
