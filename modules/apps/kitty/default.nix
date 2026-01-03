{ pkgs, lib, config, wrappers, ... }:

let
  kitty = wrappers.lib.wrapPackage {
    inherit pkgs;
    package = pkgs.kitty;
    flags = {
      "--config" = ./kitty.conf;
    };
  };

in

  {
    environment.systemPackages = lib.mkIf config.apps.enable [
      kitty
    ];
  }
