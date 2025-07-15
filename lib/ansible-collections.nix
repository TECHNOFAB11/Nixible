{
  stdenv,
  lib,
  pkgs,
}: ansible: collections: let
  inherit (lib) concatStringsSep mapAttrsToList;

  mkCollection = {
    name,
    version,
    hash,
  }:
    stdenv.mkDerivation {
      pname = name;
      inherit version;
      src = pkgs.fetchurl {
        inherit hash;
        url = "https://galaxy.ansible.com/download/${name}-${version}.tar.gz";
      };

      phases = ["installPhase"];

      installPhase = ''
        mkdir -p $out
        cp $src $out/collection.tar.gz
      '';
    };

  installCollection = collection: "${ansible}/bin/ansible-galaxy collection install ${collection}/collection.tar.gz";
  installCollections = concatStringsSep "\n" (
    mapAttrsToList (
      name: coll:
        installCollection (
          mkCollection ({inherit name;} // coll)
        )
    )
    collections
  );
in
  pkgs.runCommand "ansible-collections" {} ''
    mkdir -p $out
    export HOME=./
    export ANSIBLE_COLLECTIONS_PATH=$out
    ${installCollections}
  ''
