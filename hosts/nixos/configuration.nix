{ pkgs, ... }: {
  imports = [
    (import ../disk-config-default.nix { device = "/dev/nvme0n1"; })
  ];

  dwl = {
    enable = true;
    monitor = ''
      { "HDMI-A-1",    0.5f,  1,      1,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   0,  0 },
      { "DP-1",    0.5f,  1,      1.5f,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   1920,  0 },
      { NULL,       0.55f, 1,      1,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
    '';
  };
  cliApps.enable = true;
  apps.enable = true;
  games.enable = true;
  minecraft-server.enable = true;

  networking = {
    interfaces.enp42s0 = {
      wakeOnLan.enable = true;
    };
    firewall.allowedUDPPorts = [ 9 ];
  };
}
