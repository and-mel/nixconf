{ pkgs, lib, config, wrappers, ... }:

let
  mkMenu = menu: let
    configFile = builtins.toFile "config.yaml"
      (lib.generators.toYAML {} {
        anchor = "center";
        background = "#282828d0";
        color = "#fbf1c7";
        border = "#8ec07c";
        separator = " ➜ ";
        border_width = 2;
        corner_r = 10;
        inherit menu;
      });
    in
      pkgs.writeScript "wlr-menu" ''
        exec ${pkgs.wlr-which-key}/bin/wlr-which-key ${configFile}
      '';

  programsMenu = mkMenu [
    {
      key = "f";
      desc = "Firefox";
      cmd = "firefox-esr";
    }
    {
      key = "p";
      desc = "Prism Launcher";
      cmd = "prismlauncher";
    }
    {
      key = "z";
      desc = "Zed";
      cmd = "zeditor";
    }
  ];

  powerMenu = mkMenu [
    {
      key = "s";
      desc = "Suspend";
      cmd = "systemctl suspend";
    }
    {
      key = "p";
      desc = "Power off";
      cmd = "systemctl poweroff";
    }
    {
      key = "r";
      desc = "Reboot";
      cmd = "systemctl reboot";
    }
  ];

  configH = pkgs.writeText "config.h" ''
    #define MODKEY ${config.dwl.modkey}

    static const char *programsmenu[]    = { "${programsMenu}",  NULL };
    static const char *powermenu[]    = { "${powerMenu}",  NULL };

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
      ./restore-monitor.patch
    ];
    buildInputs = oldAttrs.buildInputs or [] ++ [ pkgs.libdrm pkgs.fcft ];
  });

  swayIdle = wrappers.lib.wrapPackage {
    inherit pkgs;
    package = pkgs.swayidle;
    flags = {
      "-C" = toString (pkgs.writeText "config" ''
        before-sleep 'swaylock -f -c 000000'
      '');
    };
  };

  dwlStartup = pkgs.writeScript "dwl-startup" ''
    #!/bin/sh
    ${pkgs.slstatus}/bin/slstatus -s | ${pkgs.dwlb}/bin/dwlb -status-stdin all & ${pkgs.dwlb}/bin/dwlb -custom-title -font "monospace:size=14" &
    ${swayIdle}/bin/swayidle &
    exec dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=wlroots
  '';

  dwlWithDwlbWrapper = pkgs.writeScriptBin "dwl-wrapped" ''
    #!/bin/sh
    exec ${lib.getExe customDwlPackage} -s "${dwlStartup}" "$@"
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
    dwl.modkey = lib.mkOption {
      type = lib.types.str;
      description = "Modkey for dwl shortcuts";
      default = "WLR_MODIFIER_LOGO";
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
          command = "${pkgs.tuigreet}/bin/tuigreet -t -c ${dwlWithDwlbWrapper}/bin/dwl-wrapped";
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
      XDG_CURRENT_DESKTOP="wlroots";
    };

    environment.systemPackages = [
      pkgs.dwlb
      pkgs.wmenu
      pkgs.slstatus
      pkgs.bibata-cursors
      pkgs.swaylock
      pkgs.slurp
      pkgs.grim
      pkgs.wlr-which-key
      swayIdle
    ];

    xdg.portal = {
      enable = true;
      config = {
        dwl = {
          default = [
            "wlr"
          ];
        };
      };
      wlr = {
        enable = true;
        settings = {
          screencast = {
            max_fps = 60;
            chooser_type = "simple";
            chooser_cmd = "${pkgs.slurp}/bin/slurp -f 'Monitor: %o' -or";
          };
        };
      };
    };
  };
}
