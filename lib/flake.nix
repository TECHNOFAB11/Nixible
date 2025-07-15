{
  outputs = {...}: {
    lib = import ./.;
    flakeModule = ./flakeModule.nix;
  };
}
