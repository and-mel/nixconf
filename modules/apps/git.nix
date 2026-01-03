{ lib, config, pkgs, ... }: {
  config = lib.mkIf config.cliApps.enable {
    programs.git = {
      enable = true;
      config = {
        user = {
          name = "and-mel";
          email = "amelikhov9836@gmail.com";
        };
        credential.helper = "oauth";
      };
    };

    environment.systemPackages = with pkgs; [
      git-credential-oauth
    ];
  };
}
