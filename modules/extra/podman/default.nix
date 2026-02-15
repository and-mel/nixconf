{ pkgs, lib, config, user, ... }: {
  options = {
    podman.enable = lib.mkEnableOption "enables podman";
  };

  config = lib.mkIf config.podman.enable {
    virtualisation = {
      containers = {
        enable = true;
        # storage = {
        #   driver = "btrfs";
        #   graphroot = "/var/lib/containers/storage";
        #   runroot = "/run/containers/storage";
        # };
      };
      podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
      };
    };

    # Automatically start containers on boot
    systemd.services.podman-autostart = {
      enable = true;
      after = [ "podman.service" ];
      wantedBy = [ "multi-user.target" ];
      description = "Automatically start containers with --restart=always tag";
      serviceConfig = {
        Type = "idle";
        User = "${user}";
        ExecStartPre = ''${pkgs.coreutils}/bin/sleep 1'';
        ExecStart = ''/run/current-system/sw/bin/podman start --all --filter restart-policy=always'';
      };
    };

    environment.systemPackages = with pkgs; [
      podman-tui
      podman-compose
    ];
  };
}
