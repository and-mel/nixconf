{ pkgs, ... }: {
  imports = [
    (import ../disk-config-default.nix { device = "/dev/nvme0n1"; })
  ];

  cliApps.enable = true;
  minecraft-server.enable = true;

  networking = {
    interfaces.enp42s0 = {
      ipv4.addresses = [{
        address = "192.168.1.152";
	prefixLength = 24;
      }];
    };
    defaultGateway = {
      address = "192.168.1.1";
      interface = "enp42s0";
    };
    nameservers = [ "1.1.1.1" "9.9.9.9" ];
  };
}
