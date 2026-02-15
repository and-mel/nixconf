{
  description = "NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    wrappers.url = "github:Lassulus/wrappers";
    impermanence.url = "github:nix-community/impermanence";
    flake-utils.url = "github:numtide/flake-utils";

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

    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
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
      {
        hostname = "t480s";
        stateVersion = "25.05";
        system = "x86_64-linux";
      }
      {
        hostname = "nixmac";
        stateVersion = "25.05";
        system = "aarch64-linux";
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
  } // (inputs.flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import inputs.nixpkgs { inherit system; };
    agenixPkg = inputs.agenix.packages."${system}".default;
    diskoPkg = inputs.disko.packages."${system}".default;
    nixosAnywherePkg = inputs.nixos-anywhere.packages."${system}".default;
  in {
    packages.install = pkgs.stdenv.mkDerivation {
      pname = "install";
      version = "0.1.0";
      src = ./scripts;
      buildInputs = [ pkgs.yq-go pkgs.git pkgs.age-plugin-fido2-hmac agenixPkg diskoPkg ];
      nativeBuildInputs = [ pkgs.makeWrapper ];

      installPhase = ''
        mkdir -p $out/bin
        cp install.sh $out/bin/install
        # Wrap the script to add dependencies to the PATH at runtime
        wrapProgram $out/bin/install --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.yq-go pkgs.git pkgs.age-plugin-fido2-hmac agenixPkg diskoPkg ]}
      '';
    };

    packages.deploy = pkgs.stdenv.mkDerivation {
      pname = "deploy";
      version = "0.1.0";
      src = ./scripts;
      buildInputs = [ pkgs.yq-go pkgs.git nixosAnywherePkg agenixPkg ];
      nativeBuildInputs = [ pkgs.makeWrapper ];

      installPhase = ''
        mkdir -p $out/bin
        cp deploy.sh $out/bin/deploy
        # Wrap the script to add dependencies to the PATH at runtime
        wrapProgram $out/bin/deploy --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.yq-go pkgs.git nixosAnywherePkg agenixPkg ]}
      '';
    };
  }));
}
