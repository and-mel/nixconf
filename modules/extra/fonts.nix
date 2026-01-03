{ pkgs, lib, config, ... }: {
  fonts = lib.mkIf config.dwl.enable {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts
    ];
    fontconfig.defaultFonts = {
      emoji = [ "Noto Color Emoji" ];
      monospace = [ "JetBrainsMono Nerd Font" ];
      sansSerif = [ "Noto Sans" ];
      serif = [ "Noto Serif" ];
    };
  };
}
