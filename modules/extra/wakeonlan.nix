{ lib, config, user, pkgs, ... }: {
  options = {
    wake-on-lan.enable = lib.mkEnableOption "enables wake on lan";
    wake-on-lan.hass-control.enable = lib.mkEnableOption "enables control access from Home Assistant";
    wake-on-lan.interface = lib.mkOption {
      type = lib.types.str;
      description = "Network interface for wake on lan";
      default = "";
    };
  };

  config = lib.mkIf config.wake-on-lan.enable {
    networking = {
      interfaces.${config.wake-on-lan.interface} = {
        wakeOnLan.enable = true;
      };
      firewall.allowedUDPPorts = [ 9 ];
    };

    users.users.${user}.openssh.authorizedKeys = lib.mkIf config.wake-on-lan.hass-control.enable {
      keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIELAD2Z1NGN5YAf1clMgOwbEBuX+lfI9V9ftJsTnVK3k homeassistant"
      ];
    };

    security.sudo = lib.mkIf config.wake-on-lan.hass-control.enable {
      extraRules = [{
        commands = [
          {
            command = "${pkgs.systemd}/bin/systemctl suspend";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.systemd}/bin/reboot";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.systemd}/bin/poweroff";
            options = [ "NOPASSWD" ];
          }
        ];
        groups = [ "wheel" ];
      }];
    };
  };
}
