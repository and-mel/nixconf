{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.obs-studio = lib.mkIf config.apps.enable {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-vaapi
      obs-pipewire-audio-capture
      obs-vkcapture
    ];
  };
}
