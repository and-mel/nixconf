{ pkgs, ... }: {
  imports = [
    (import ../disk-config-default.nix { device = "/dev/nvme0n1"; })
  ];

  dwl = {
    enable = true;
    monitor = ''
      { "HDMI-A-2",    0.55f,  1,      1,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   1920,  0 },
      { "eDP-1",    0.5f,  1,      1,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   0,  0 },
      { NULL,       0.55f, 1,      1,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
    '';
  };
  cliApps.enable = true;
  apps.enable = true;
  games.enable = true;
  wake-on-lan = {
    enable = true;
    interface = "enp0s31f6";
    hass-control.enable = true;
  };
}
