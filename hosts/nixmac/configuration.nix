{ pkgs, ... }: {
  imports = [
    (import ../disk-config-default.nix { device = "/dev/vda"; })
  ];

  dwl = {
    enable = true;
    monitor = ''
      { NULL,       0.55f, 1,      1,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
    '';
    modkey = "WLR_MODIFIER_ALT";
  };
  cliApps.enable = true;
  apps.enable = true;
  games.enable = true;

  environment.systemPackages = [
    pkgs.spice-vdagent
  ];
}
