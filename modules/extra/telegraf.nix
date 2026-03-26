{
  pkgs,
  lib,
  config,
  ...
}:
{
  options = {
    telegraf.enable = lib.mkEnableOption "enables telegraf";
  };

  config = lib.mkIf config.telegraf.enable {
    services.telegraf = {
      enable = true;
      extraConfig = {
        inputs = {
          mqtt_consumer = {
            servers = [ "tcp://192.168.2.155:1883" ];
          };
        };
      };
    };
  };
}
