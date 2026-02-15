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
    firewall.enable = false;
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

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

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
    };
  };

  users.mutableUsers = false;
  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    hashedPasswordFile = config.age.secrets.passwd-andrei.path;
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIACw2AMBYcoTWNCWZKYlliS3Naw4kFuhAxFr3LDmsdnBAAAABHNzaDo="
    ];
  };

  environment.systemPackages = with pkgs; [
    age-plugin-fido2-hmac
  ];

  users.defaultUserShell = pkgs.zsh;

  services.logrotate.checkConfig = false;

  system.stateVersion = stateVersion;
}
