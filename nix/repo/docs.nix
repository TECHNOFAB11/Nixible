{inputs, ...}: let
  inherit (inputs) pkgs doclib nblib;

  optionsDoc = doclib.mkOptionDocs {
    module = nblib.module;
    roots = [
      {
        url = "https://gitlab.com/TECHNOFAB/nixible/-/blob/main/lib";
        path = "${inputs.self}/lib";
      }
    ];
  };
  optionsDocs = pkgs.runCommand "options-docs" {} ''
    mkdir -p $out
    ln -s ${optionsDoc} $out/options.md
  '';
in
  (doclib.mkDocs {
    docs."default" = {
      base = "${inputs.self}";
      path = "${inputs.self}/docs";
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
        includeDir = toString optionsDocs;
      };
      config = {
        site_name = "Nixible";
        site_url = "https://nixible.projects.tf";
        repo_name = "TECHNOFAB/nixible";
        repo_url = "https://gitlab.com/TECHNOFAB/nixible";
        extra_css = ["style.css"];
        theme = {
          logo = "images/logo.svg";
          icon.repo = "simple/gitlab";
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
  }).packages
  // {inherit optionsDocs;}
