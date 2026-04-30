{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  options = {
    vpn-server.enable = lib.mkEnableOption "enables xray vpn server";
  };

  config =
    let
      private = inputs.nixconf-mcserver.identities;
    in lib.mkIf config.vpn-server.enable {
    networking.firewall = {
      allowedTCPPorts = [
        80
        443
      ];
    };

    # 1. Create the user and group manually
    users.users.xray = {
      isSystemUser = true;
      group = "xray";
      extraGroups = [ "acme" ]; # Now this will work!
    };
    users.groups.xray = {};
    users.users.nginx.extraGroups = [ "xray" "acme" ];

    # 2. Tell the Xray service to use this persistent user
    systemd.services.xray.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "xray";
      Group = "xray";
    };

    services.xray = {
      enable = true;
      settingsFile = pkgs.writeText "config-server.jsonc" (builtins.toJSON {
        log = {
          loglevel = "warning";
        };
        inbounds = [
          {
            port = 443;
            protocol = "vless";
            settings = {
              clients = private.xray.clients;
              decryption = "none";
              fallbacks = [
                {
                  dest = 80;
                }
              ];
            };
            streamSettings = {
              network = "tcp";
              security = "tls";
              tlsSettings = {
                serverName = private.xray.domain;
                alpn = [ "http/1.1" "h2" ];
                certificates = [
                  {
                    certificateFile = "/var/lib/acme/${private.xray.domain}/fullchain.pem";
                    keyFile = "/var/lib/acme/${private.xray.domain}/key.pem";
                  }
                ];
              };
            };
          }
        ];
        outbounds = [
          {
            protocol = "freedom";
          }
        ];
      });
    };

    services.nginx = {
      enable = true;
      virtualHosts."${private.xray.domain}" = {
        default = true;
        # forceSSL = true;
        root = "/var/www/html";
        enableACME = true;
        addSSL = false;
      };
    };

    security.acme = {
      acceptTerms = true;
      defaults = {
        email = private.xray.email;
        environmentFile = config.age.secrets.acme-env.path;
        dnsProvider = "cloudflare";
        dnsPropagationCheck = true;
      };
      certs."${private.xray.domain}" = {
        group = "xray";
        reloadServices = [
          "nginx.service"
          "xray.service"
        ];
      };
    };

    # Symlink index.html to the Nginx root directory
    systemd.tmpfiles.rules = [
      "L+ /var/www/html/index.html - - - - ${./index.html}"
    ];
  };

  #   environment.systemPackages = with pkgs; [
  #     shadowsocks-rust
  #     cloak-pt
  #     wstunnel
  #   ];
  # };
}
