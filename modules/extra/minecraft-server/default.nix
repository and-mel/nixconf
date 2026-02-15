{ pinnedPkgs, pkgs, lib, config, user, ... }: {
  options = {
    minecraft-server.enable = lib.mkEnableOption "enables Minecraft server";
    minecraft-server.ip = lib.mkOption {
      type = lib.types.str;
      description = "Minecraft server IP for port forwarding (DO NOT specify if you dont want port forwarding!)";
      default = "";
    };
  };

  config = lib.mkIf config.minecraft-server.enable {
    services.minecraft-server = {
      enable = true;
      package = pinnedPkgs.minecraft-server;
      eula = true;
      jvmOpts = "-Xmx8192M -Xms8192M";
      openFirewall = true;
    };

    environment.systemPackages = with pkgs; [
      miniupnpc
    ];

    systemd.services.open-upnp-port = lib.mkIf (config.minecraft-server.ip != "") {
      script = ''
        ${lib.getExe pkgs.miniupnpc} -a ${config.minecraft-server.ip} 25565 25565 tcp
      '';

      # This service runs once and finishes,
      # instead of the default long-live services
      serviceConfig = {
        Type = "oneshot";
      };

      # "Enable" the service
      wantedBy = [ "multi-user.target" ];
    };
  };
}
