{inputs, ...}: let
  inherit (inputs) pkgs ntlib nblib;
in {
  tests = ntlib.mkNixtest {
    modules = ntlib.autodiscover {dir = "${inputs.self}/tests";};
    args = {
      inherit pkgs ntlib nblib;
    };
  };
}
