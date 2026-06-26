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
    ./git.nix
    ./obs-studio.nix
    ./zen-browser.nix
    ./steam.nix
  ];

  config = {
    environment.systemPackages =
      with pkgs;
      lib.optionals config.apps.enable [
        (writeShellScriptBin "libreoffice" ''
          export SAL_USE_VCLPLUGIN=kf6
          exec ${libreoffice-qt}/bin/libreoffice "$@"
        '')
        hunspell
        hunspellDicts.en_US
        zed-editor
        keepassxc
        spotify
        thunar
        mpv
        losslesscut-bin
        adwaita-icon-theme
        # jetbrains.idea
      ]
      ++ lib.optionals config.cliApps.enable [
        neovim
        direnv
      ]
      ++ lib.optionals config.games.enable [
        prismlauncher
        lutris
      ];
  };
}
