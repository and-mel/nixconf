{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
{
  options = {
    vpn-client.enable = lib.mkEnableOption "enables mihomo vpn client";
    vpn-client.login = lib.mkOption {
      type = lib.types.str;
      description = "Client alias for Xray login";
      default = "";
    };
  };

  config =
    let
      private = inputs.nixconf-mcserver.identities;

      clientsByAlias = builtins.listToAttrs (
        map (client: {
          name = client.alias;
          value = client;
        }) private.xray.clients
      );
    in
    lib.mkIf config.vpn-client.enable {
      services.mihomo = {
        enable = true;
        tunMode = true;
        configFile = pkgs.writeText "config.yaml" ''
          proxies:
            - name: vless
              type: vless
              server: ${private.xray.domain}
              port: 443
              udp: false
              uuid: ${(clientsByAlias.${config.vpn-client.login}).id}
              flow: xtls-rprx-vision
              tls: true
              servername: ${private.xray.domain}
              alpn:
              - h2
              - http/1.1
              encryption: none
              network: tcp
              smux:
                enabled: false
          redir-port: 7895
          mixed-port: 7897
          socks-port: 7898
          port: 7899
          log-level: info
          allow-lan: false
          ipv6: false
          mode: global

          dns:
            enable: true
            enhanced-mode: fake-ip
            listen: 127.0.0.1:1053
            ipv6: false
            nameserver:
              - 1.1.1.1
              - 8.8.8.8

          tun:
            enable: true
            auto-detect-interface: true
            auto-route: true
            device: tun0
            dns-hijack:
            - any:53
            mtu: 1500
            route-exclude-address: []
            stack: system
            strict-route: true

          proxy-groups:
            - name: GLOBAL
              type: select
              proxies:
                - vless

          external-controller-cors:
            allow-private-network: true
            allow-origins:
            - tauri://localhost
            - http://tauri.localhost
            - https://yacd.metacubex.one
            - https://metacubex.github.io
            - https://board.zash.run.place
          unified-delay: true
        '';
      };
      networking.firewall = {
        trustedInterfaces = [ "tun0" ];
        checkReversePath = "loose";
      }; # boot.kernel.sysctl = { # "net.ipv4.conf.all.rp_filter" = 0; # "net.ipv4.conf.default.rp_filter" = 0; # "net.ipv4.conf.tun0.rp_filter" = 0; # }; };
    };
}
