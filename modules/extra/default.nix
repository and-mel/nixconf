{ lib, config, ... }: {
  imports = [
    ./dwl
    ./minecraft-server
    ./podman
    ./fonts.nix
    ./wakeonlan.nix
  ];
}
