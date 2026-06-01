{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.games.enable {
    programs.steam = {
      enable = true;
    };
    environment.systemPackages = with pkgs; [
      wineWowPackages.stable
      winetricks
    ];
  };
}
