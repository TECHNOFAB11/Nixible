{
  pkgs,
  ntlib,
  ...
}: {
  suites."flake-parts" = {
    pos = __curPos;
    tests = [
      {
        name = "flakeModule";
        type = "script";
        script =
          # sh
          ''
            ${ntlib.helpers.path (with pkgs; [coreutils nix gnused gnugrep jq])}
            ${ntlib.helpers.scriptHelpers}
            export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
            export NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
            repo_path=${../.}

            cp ${./fixtures/flake_parts}/* .
            # import from the absolute path above, is easier than trying to figure out the repo path etc.
            sed -i -e "s|@repo_path@|$repo_path|" flake.nix

            # NOTE: --impure is required since importing modules from absolute paths is not allowed in pure mode
            nix build --impure .#nixible:test
            assert "-f result/bin/nixible" "should exist"
            assert_file_contains "result/bin/nixible" "ANSIBLE_COLLECTIONS_PATH"
            assert_file_contains "result/bin/nixible" "ansible-playbook"

            nix build --impure .#nixible:hello
            assert "-f result/bin/nixible" "should exist"
            assert_file_contains "result/bin/nixible" "ANSIBLE_COLLECTIONS_PATH"
            assert_file_contains "result/bin/nixible" "ansible-playbook"
          '';
      }
    ];
  };
}
