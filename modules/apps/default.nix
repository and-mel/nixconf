{ lib, config, user, pkgs, ... }: {
  options = {
    apps.enable = lib.mkEnableOption "enables core apps";
    cliApps.enable = lib.mkEnableOption "enables core CLIs";
    games.enable = lib.mkEnableOption "enables games";
  };

  imports = [
    ./kitty
    ./firefox.nix
    ./git.nix
  ];

  config = {
    environment.systemPackages = with pkgs;
    lib.optionals config.apps.enable [
      zed-editor
      vesktop
    ] ++ lib.optionals config.cliApps.enable [
      neovim
    ] ++ lib.optionals config.games.enable [
      prismlauncher
    ];
  };
}
