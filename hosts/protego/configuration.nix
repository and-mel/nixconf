{ pkgs, ... }: {
  imports = [
    # (import ../disk-config-default.nix { device = "/dev/nvme0n1"; })
  ];

  dwl.enable = true;
  cliApps.enable = true;
  apps.enable = true;
  games.enable = true;

  boot.extraModprobeConfig = ''
    options rtw89_pci disable_clkreq=y disable_aspm_l1=y disable_aspm_l1ss=y
  '';
}
