{ pkgs, lib, config, user, ... }: {
  options = {
    minecraft-server.enable = lib.mkEnableOption "enables Minecraft server";
  };

  config = lib.mkIf config.minecraft-server.enable {
    services.minecraft-server = {
      enable = true;
      eula = true;
      jvmOpts = "-Xmx8192M -Xms8192M";
      openFirewall = true;
    };
  };
}
