{ pkgs, ... }: {
  imports = [
    (import ../disk-config-default.nix { device = "/dev/sda"; })
  ];

  dwl = {
    enable = true;
    monitor = ''
      { "eDP-1",    0.5f,  1,      1,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   0,  0 },
      { NULL,       0.55f, 1,      1,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
    '';
  };
  boot.initrd.kernelModules = [ "i915" ];
  cliApps.enable = true;
  apps.enable = true;
  games.enable = true;

  environment.systemPackages = [ pkgs.jetbrains.idea ];
}
