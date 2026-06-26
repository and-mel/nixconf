{
  hostname,
  stateVersion,
  lib,
  config,
  user,
  pkgs,
  ...
}:
{
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
    firewall.enable = true;
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;

  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    earlySetup = true;
    keyMap = "us";

    # Install the dedicated terminus package to the console environment
    packages = [ pkgs.terminus_font ];

    # Use the official Terminus naming scheme:
    # 'ter-v' (video variant), '16' (size), 'n' (normal) or 'b' (bold)
    font = "ter-v20b";
  };

  programs.nh = {
    enable = true;
    flake = "/home/${user}/nixos";
  };

  services.speechd.enable = lib.mkForce false;
  security.rtkit.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
    };
  };

  users.mutableUsers = false;
  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    hashedPasswordFile = config.age.secrets.passwd-andrei.path;
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIACw2AMBYcoTWNCWZKYlliS3Naw4kFuhAxFr3LDmsdnBAAAABHNzaDo="
    ];
  };

  environment.systemPackages = with pkgs; [
    age-plugin-fido2-hmac
    nil
    nixd
    cifs-utils
    samba
  ];

  fileSystems."/mnt/share" = {
    device = "//ds2/home";
    fsType = "cifs";
    options = [
      "x-systemd.automount" # Mounts automatically when accessed
      "noauto" # Don't fail boot if the server is offline
      "nofail" # Allows boot to continue if mounting fails
      "uid=1000" # Changes owner of files to your NixOS user UID
      "gid=100" # Changes group to your NixOS user GID
      "credentials=${config.age.secrets.passwd-ds2.path}" # Path to your username/password
    ];
  };
  boot.supportedFilesystems = [ "cifs" ];

  users.defaultUserShell = pkgs.zsh;

  services.logrotate.checkConfig = false;

  system.stateVersion = stateVersion;
}
