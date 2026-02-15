{ pkgs, ... }: {
  imports = [
    (import ../disk-config-default.nix { device = "/dev/nvme0n1"; })
  ];

  cliApps.enable = true;
  mcserver.enable = true;
}
