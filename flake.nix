{
  outputs = {
    flake-parts,
    systems,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.devenv.flakeModule
        inputs.treefmt-nix.flakeModule
        inputs.nix-gitlab-ci.flakeModule
        inputs.nix-mkdocs.flakeModule
        ./lib/flakeModule.nix
      ];
      systems = import systems;
      flake = {};
      perSystem = {
        lib,
        pkgs,
        self',
        config,
        ...
      }: {
        treefmt = {
          projectRootFile = "flake.nix";
          programs = {
            alejandra.enable = true;
            mdformat.enable = true;
          };
        };
        devenv.shells.default = {
          containers = pkgs.lib.mkForce {};

          git-hooks.hooks = {
            treefmt = {
              enable = true;
              packageOverrides.treefmt = config.treefmt.build.wrapper;
            };
            convco.enable = true;
          };
        };
        docs."default".config = {
          path = ./docs;
          material = {
            enable = true;
            colors = {
              primary = "black";
              accent = "blue";
            };
            umami = {
              enable = true;
              src = "https://analytics.tf/umami";
              siteId = "d8354dfa-2ad2-4089-90d2-899b981aef22";
              domains = ["nixible.projects.tf"];
            };
          };
          macros = {
            enable = true;
            includeDir = toString self'.packages.optionsDocs;
          };
          config = {
            site_name = "Nixible";
            site_url = "https://nixible.projects.tf";
            repo_name = "TECHNOFAB/nixible";
            repo_url = "https://gitlab.com/TECHNOFAB/nixible";
            extra_css = ["style.css"];
            theme = {
              icon.repo = "simple/gitlab";
              logo = "images/logo.svg";
              favicon = "images/logo.svg";
            };
            nav = [
              {"Introduction" = "index.md";}
              {"Usage" = "usage.md";}
              {"Examples" = "examples.md";}
              {"Reference" = "reference.md";}
              {"Options" = "options.md";}
            ];
            markdown_extensions = [
              "pymdownx.superfences"
              "admonition"
            ];
          };
        };
        ci = {
          stages = ["test" "build" "deploy"];
          jobs = {
            "test:lib" = {
              stage = "test";
              script = [
                "nix run .#tests -- --junit=junit.xml"
              ];
              allow_failure = true;
              artifacts = {
                when = "always";
                reports.junit = "junit.xml";
              };
            };
            "docs" = {
              stage = "build";
              script = [
                # sh
                ''
                  nix build .#docs:default
                  mkdir -p public
                  cp -r result/. public/
                ''
              ];
              artifacts.paths = ["public"];
            };
            "pages" = {
              nix.enable = false;
              image = "alpine:latest";
              stage = "deploy";
              script = ["true"];
              artifacts.paths = ["public"];
              rules = [
                {
                  "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH";
                }
              ];
            };
          };
        };

        nixible = {
          "hello".playbook = [
            {
              name = "Hello World";
              hosts = "localhost";
              tasks = [
                {
                  name = "Say hello";
                  debug.msg = "Hello from Nixible!";
                }
              ];
            }
          ];
          "another".playbook = [];
        };

        packages = let
          nblib = import ./lib {inherit pkgs lib;};
          ntlib = inputs.nixtest.lib {inherit pkgs lib;};
          doclib = inputs.nix-mkdocs.lib {inherit lib pkgs;};
        in rec {
          tests = ntlib.mkNixtest {
            modules = ntlib.autodiscover {dir = ./tests;};
            args = {
              inherit pkgs nblib ntlib;
            };
          };
          optionsDoc = doclib.mkOptionDocs {
            module = {
              imports = [
                nblib.module
                {
                  _module.args.pkgs = pkgs;
                }
              ];
            };
            roots = [
              {
                url = "https://gitlab.com/TECHNOFAB/nixible/-/blob/main/lib";
                path = toString ./lib;
              }
            ];
          };
          optionsDocs = pkgs.runCommand "options-docs" {} ''
            mkdir -p $out
            ln -s ${optionsDoc} $out/options.md
          '';
        };
      };
    };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # flake & devenv related
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default-linux";
    devenv.url = "github:cachix/devenv";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    nix-gitlab-ci.url = "gitlab:technofab/nix-gitlab-ci?dir=lib";
    nixtest.url = "gitlab:technofab/nixtest?dir=lib";
    nix-mkdocs.url = "gitlab:technofab/nixmkdocs?dir=lib";
    mkdocs-material-umami.url = "gitlab:technofab/mkdocs-material-umami";
  };

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://devenv.cachix.org"
    ];

    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };
}
