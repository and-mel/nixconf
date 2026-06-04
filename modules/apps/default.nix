{
  lib,
  config,
  pkgs,
  ...
}:
{
  options = {
    apps.enable = lib.mkEnableOption "enables core apps";
    cliApps.enable = lib.mkEnableOption "enables core CLIs";
    games.enable = lib.mkEnableOption "enables games";
  };

  imports = [
    ./kitty
    ./firefox.nix
    ./git.nix
    ./zen-browser.nix
    ./steam.nix
  ];

  config = {
    environment.systemPackages =
      with pkgs;
      lib.optionals config.apps.enable [
        zed-editor
        keepassxc
        spotify
        xfce.thunar
        # jetbrains.idea
      ]
      ++ lib.optionals config.cliApps.enable [
        neovim
        direnv
      ]
      ++ lib.optionals config.games.enable [
        prismlauncher
      ];
  };
}
