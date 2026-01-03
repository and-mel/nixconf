{ pkgs, lib, config, ... }:

let
  configH = pkgs.writeText "config.h" ''
    ${builtins.readFile ./config.h}

    static const MonitorRule monrules[] = {
      ${config.dwl.monitor}
    };
  '';
  customDwlPackage = (pkgs.dwl.override {
    inherit configH;
  }).overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or []) ++ [
      ./movestack.patch
      ./cursortheme.patch
    ];
    buildInputs = oldAttrs.buildInputs or [] ++ [ pkgs.libdrm pkgs.fcft ];
  });

  dwlWithDwlbWrapper = pkgs.writeScriptBin "dwl" ''
    #!/bin/sh
    exec ${lib.getExe customDwlPackage} -s "${pkgs.slstatus}/bin/slstatus -s | ${pkgs.dwlb}/bin/dwlb -status-stdin all & ${pkgs.dwlb}/bin/dwlb -custom-title -font \"monospace:size=14\"" "$@"
  '';

in

{
  options = {
    dwl.enable = lib.mkEnableOption "enables dwl";
    dwl.monitor = lib.mkOption {
      type = lib.types.str;
      description = "Monitor rules for dwl";
      default = ''
        { NULL,       0.55f, 1,      1,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
      '';
    };
  };

  config = lib.mkIf config.dwl.enable {
    hardware.graphics.enable = true;

    services.pipewire = {
      enable = true;
      pulse.enable = true;
    };

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet -t -c ${dwlWithDwlbWrapper}/bin/dwl";
        };
      };
      useTextGreeter = true;
    };

    services.logind.settings.Login = {
      HandlePowerKey = "suspend";
    };

    programs.dwl = {
      enable = true;
      package = dwlWithDwlbWrapper;
    };

    environment.systemPackages = with pkgs; [
      dwlb
      wmenu
      slstatus
      bibata-cursors
    ];
  };
}
