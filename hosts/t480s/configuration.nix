{ pkgs, ... }: {
  imports = [
    (import ../disk-config-default.nix { device = "/dev/nvme0n1"; })
  ];

  dwl = {
    enable = true;
  };
  cliApps.enable = true;
  apps.enable = true;
  games.enable = true;
}
