{
  imports = [
    (import ../disk-config-default.nix { device = "/dev/sda"; })
  ];

  cliApps.enable = true;
  wake-on-lan = {
    enable = true;
    interface = "eno1";
    hass-control.enable = true;
  };

  networking = {
    interfaces.eno1 = {
      ipv4.addresses = [
        {
          address = "192.168.1.157";
          prefixLength = 24;
        }
      ];
    };
    # interfaces.enp33s0 = {
    #   ipv4.addresses = [
    #     {
    #       address = "192.168.3.152";
    #       prefixLength = 24;
    #     }
    #   ];
    # };
    defaultGateway = {
      address = "192.168.2.222";
      interface = "eno1";
    };
    nameservers = [
      "1.1.1.1"
      "9.9.9.9"
    ];
  };
}
