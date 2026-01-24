{ pkgs, lib, config, wrappers, ... }:

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

  swayIdle = wrappers.lib.wrapPackage {
    inherit pkgs;
    package = pkgs.swayidle;
    flags = {
      "-C" = toString (pkgs.writeText "config" ''
        before-sleep 'swaylock -f -c 000000'
      '');
    };
  };
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

    security.pam.services.swaylock = {
      text = ''
        auth include login
      '';
    };

    programs.dwl = {
      enable = true;
      package = dwlWithDwlbWrapper;
    };

    # programs.dconf = {
    #   enable = true;
    #   profiles.user.databases = [
    #     {
    #       settings = {
    #         "org/gnome/desktop/interface" = {
    #           color-scheme = "prefer-dark";
    #         };
    #       };
    #     }
    #   ];
    # };

    qt = {
      enable = true;
      platformTheme = "gtk2";
      style = "adwaita-dark";
    };

    # xdg.portal = {
    #   enable = true;
    #   config = {
    #     common = {
    #       default = [
    #         "gtk"
    #       ];
    #     };
    #   };
    # };

    environment.sessionVariables = {
      GTK_THEME = "Adwaita-dark";
    };

    environment.systemPackages = [
      pkgs.dwlb
      pkgs.wmenu
      pkgs.slstatus
      pkgs.bibata-cursors
      pkgs.swaylock
      swayIdle
    ];
  };
}
