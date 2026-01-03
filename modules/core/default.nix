{ hostname, stateVersion, lib, config, user, pkgs, ... }: {
  imports = [
    ./boot.nix
    ./zsh.nix
    ./age.nix
    ./hjem.nix
    ./impermanence.nix
  ];

  networking = {
    hostName = hostname;
    networkmanager.enable = true;
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    earlySetup = true;
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  programs.nh = {
    enable = true;
    flake = "/home/${user}/nixos";
  };

  services.speechd.enable = lib.mkForce false;

  services.openssh.enable = true;

  users.mutableUsers = false;
  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    hashedPasswordFile = config.age.secrets.passwd-andrei.path;
  };

  users.defaultUserShell = pkgs.zsh;

  services.logrotate.checkConfig = false;

  system.stateVersion = stateVersion;
}
