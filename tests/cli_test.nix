{
  pkgs,
  nblib,
  ntlib,
  ...
}: {
  suites."CLI Tests" = {
    pos = __curPos;
    tests = [
      {
        name = "dependencies inclusion";
        type = "script";
        script = let
          config = {pkgs, ...}: {
            dependencies = [pkgs.git pkgs.curl];
            playbook = [
              {
                name = "Test dependencies";
                hosts = "localhost";
                tasks = [];
              }
            ];
          };
          cli = nblib.mkNixibleCli config;
        in
          # sh
          ''
            ${ntlib.helpers.scriptHelpers}

            # check that dependencies are included in runtime inputs
            assert_file_contains "${cli}/bin/nixible" "${pkgs.git}" "should include git in PATH"
            assert_file_contains "${cli}/bin/nixible" "${pkgs.curl}" "should include curl in PATH"
          '';
      }
      {
        name = "CLI executable structure";
        type = "script";
        script = let
          config = {pkgs, ...}: {
            dependencies = [pkgs.git];
            playbook = [
              {
                name = "CLI test";
                hosts = "localhost";
                tasks = [
                  {
                    debug.msg = "Testing CLI";
                  }
                ];
              }
            ];
          };
          cli = nblib.mkNixibleCli config;
        in
          # sh
          ''
            ${ntlib.helpers.scriptHelpers}

            # check CLI is executable
            assert "-x ${cli}/bin/nixible" "CLI should be executable"

            # check wrapper content
            assert_file_contains "${cli}/bin/nixible" "set -euo pipefail" "should have error handling"
            assert_file_contains "${cli}/bin/nixible" "ansible-playbook" "should call ansible-playbook"
            assert_file_contains "${cli}/bin/nixible" "git rev-parse --show-toplevel" "should detect git repo"
          '';
      }
      {
        name = "variables setup";
        type = "script";
        script = let
          config = {
            playbook = [
              {
                name = "Environment test";
                hosts = "localhost";
                tasks = [];
              }
            ];
          };
          cli = nblib.mkNixibleCli config;
        in
          # sh
          ''
            ${ntlib.helpers.scriptHelpers}

            assert_file_contains "${cli}/bin/nixible" 'export ANSIBLE_COLLECTIONS_PATH=' "should export collections path"
            assert_file_contains "${cli}/bin/nixible" '-e "pwd=$(pwd)"' "should pass pwd variable"
            assert_file_contains "${cli}/bin/nixible" '-e "git_root=$git_repo"' "should pass git_root variable"
          '';
      }
      {
        name = "runtime dependencies inclusion";
        type = "script";
        script = let
          config = {pkgs, ...}: {
            dependencies = [pkgs.rsync pkgs.openssh];
            playbook = [
              {
                name = "Dependencies test";
                hosts = "localhost";
                tasks = [];
              }
            ];
          };
          cli = nblib.mkNixibleCli config;
        in
          # sh
          ''
            ${ntlib.helpers.scriptHelpers}

            # check runtime dependencies are properly included
            assert_file_contains "${cli}/bin/nixible" "rsync" "should include rsync from runtimeInputs"
            assert_file_contains "${cli}/bin/nixible" "openssh" "should include openssh from runtimeInputs"
          '';
      }
    ];
  };
}
