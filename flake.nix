{
  description = "NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    wrappers.url = "github:Lassulus/wrappers";
    impermanence.url = "github:nix-community/impermanence";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mysecrets = {
      url = "git+ssh://git@github.com/and-mel/nixconf-secrets.git?ref=main&shallow=1";
      flake = false;
    };
  };

  outputs = inputs: let

    user = "andrei";
    hosts = [
      {
        hostname = "protego";
        stateVersion = "25.05";
        system = "x86_64-linux";
      }
      {
        hostname = "nixos";
        stateVersion = "25.05";
        system = "x86_64-linux";
      }
    ];

    makeSystem =
      {
        hostname,
        system,
        stateVersion,
      }:
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          wrappers = inputs.wrappers;
          inherit
            inputs
            stateVersion
            hostname
            user
            ;
        };

        modules = [
          inputs.impermanence.nixosModules.impermanence
          inputs.disko.nixosModules.disko
          inputs.agenix.nixosModules.default
          inputs.hjem.nixosModules.default
          ./hosts/${hostname}/configuration.nix
          ./hosts/${hostname}/hardware-configuration.nix
          ./modules
        ];
      };

  in {
    nixosConfigurations = inputs.nixpkgs.lib.foldl' (
      configs: host:
      configs
      // {
        "${host.hostname}" = makeSystem {
          inherit (host) hostname system stateVersion;
        };
      }
    ) { } hosts;
  };
}
