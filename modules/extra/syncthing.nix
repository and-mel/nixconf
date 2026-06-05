{
  inputs,
  config,
  lib,
  hostname,
  user,
  ...
}:
{
  options = {
    syncthing.enable = lib.mkEnableOption "enables syncthing";
  };

  config =
    let
      identities = inputs.nixconf-mcserver.identities.syncthing;
      allDevices = identities.devices;

      # Filter out current host for the 'devices' list
      otherDevices = lib.filterAttrs (name: id: name != hostname) allDevices;
    in
    lib.mkIf config.syncthing.enable {
      networking.firewall = {
        allowedTCPPorts = [ 22000 ];
        allowedUDPPorts = [ 22000 ];
      };

      age.secrets."syncthing-cert" = {
        file = "${inputs.mysecrets}/syncthing/${hostname}/cert.age";
        owner = "syncthing";
      };
      age.secrets."syncthing-key" = {
        file = "${inputs.mysecrets}/syncthing/${hostname}/key.age";
        owner = "syncthing";
      };

      users.users.syncthing = {
        enable = true;
        group = "users";
        isSystemUser = true;
      };

      services.syncthing = {
        enable = true;
        relay.enable = false;
        inherit user;
        group = "users";
        cert = config.age.secrets."syncthing-cert".path;
        key = config.age.secrets."syncthing-key".path;
        settings = {
          devices = lib.mapAttrs (name: id: {
            inherit id;
            # If THIS host is an introducer, it tells others about the mesh.
            introducer = if name == "fractal" then true else false;
            autoAcceptFolders = if name == "fractal" then true else false;
            addresses =
              if name == "fractal" then
                [
                  "tcp://192.168.2.157"
                ]
              else
                [ ];
          }) otherDevices;
          options = {
            globalAnnounceEnabled = false; # No Global Discovery
            localAnnounceEnabled = false; # No LAN Discovery
            relaysEnabled = false; # No Relays
          };
          folders."Passwords" = {
            path = "/home/${user}/KeePassXC";
            devices = builtins.attrNames otherDevices;
            # Ensure this host stays in sync with the hub
            versioning = {
              type = "simple";
              params.keep = "10";
            };
          };
        };
      };

      systemd.tmpfiles.rules = [
        "d /home/${user}/KeePassXC 0700 ${user} users -"
      ];
    };
}
