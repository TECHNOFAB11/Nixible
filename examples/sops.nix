{pkgs, ...}: {
  #
  # NOTE: needs a .sops.yaml file in the directory to work
  #
  dependencies = [pkgs.sops];

  collections = {
    "community-crypto" = {
      version = "3.0.0";
      hash = "sha256-sRuv2qateLgZRWlTtHO1f2hb4vb7Oc/2DHTuLmexuiI=";
    };
    "community-sops" = {
      version = "2.1.0";
      hash = "sha256-5VGVBV+z4bUe6XdKu5P8+HbABCvgeR8hvDmL5s1BfUM=";
    };
  };

  playbook = [
    {
      name = "Create SOPS-encrypted private key";
      hosts = "localhost";
      tasks = [
        {
          block = [
            {
              name = "Create private key";
              "community.crypto.openssl_privatekey_pipe" = {
                size = 2048;
                content =
                  # jinja
                  ''
                    {{ lookup(
                      'community.sops.sops',
                      "{{ pwd }}/keys/private_key.pem.sops",
                      config_path='${./.sops.yaml}',
                      empty_on_not_exist=true) }}
                  '';
              };
              no_log = true;
              register = "private_key";
            }
            {
              name = "Write encrypted key to disk";
              when = "private_key is changed";
              "community.sops.sops_encrypt" = {
                path = "{{ pwd }}/keys/private_key.pem.sops";
                content_text = "{{ private_key.privatekey }}";
                config_path = ./.sops.yaml;
              };
            }
          ];
          always = [
            {
              name = "Wipe private key from Ansible's facts";
              set_fact.private_key = "";
            }
          ];
        }
      ];
    }
  ];
}
