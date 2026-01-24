{ lib, config, pkgs, ... }: {
  config = lib.mkIf config.cliApps.enable {
    programs.git = {
      enable = true;
      config = {
        user = {
          name = "and-mel";
          email = "amelikhov9836@gmail.com";
        };
      };
    };
  };
}
