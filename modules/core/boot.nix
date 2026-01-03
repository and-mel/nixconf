{
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 30;
    };

    efi.canTouchEfiVariables = true;
  };
}
