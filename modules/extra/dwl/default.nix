{
  pkgs,
  lib,
  config,
  wrappers,
  inputs,
  ...
}:

let
  pkgs-25-11 = import inputs.nixpkgs-25-11 {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowFree = true;
  };

  mkMenu =
    menu:
    let
      configFile = builtins.toFile "config.yaml" (
        lib.generators.toYAML { } {
          anchor = "center";
          background = "#282828d0";
          color = "#fbf1c7";
          border = "#8ec07c";
          separator = " ➜ ";
          border_width = 2;
          corner_r = 10;
          inherit menu;
        }
      );
    in
    pkgs.writeScript "wlr-menu" ''
      exec ${pkgs.wlr-which-key}/bin/wlr-which-key ${configFile}
    '';

  programsMenu = mkMenu [
    {
      key = "f";
      desc = "Zen";
      cmd = "zen";
    }
    {
      key = "g";
      desc = "Geometry Dash";
      cmd = "steam steam://rungameid/322170";
    }
    {
      key = "p";
      desc = "Prism Launcher";
      cmd = "prismlauncher";
    }
    {
      key = "s";
      desc = "Spotify";
      cmd = "spotify";
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

  kanshiConfig = pkgs.writeText "kanshi-config" ''
    profile undocked {
        output eDP-1 enable
    }

    profile docked {
        output eDP-1 disable
        output DP-2 enable position 0,0
    }
  '';

  kanshi = wrappers.lib.wrapPackage {
    inherit pkgs;
    package = pkgs.kanshi;
    flags = {
      "-c" = "${kanshiConfig}";
    };
  };

  i3statusConfig = pkgs.writeText "i3status.conf" ''
    general {
        output_format = "none"
        interval = 1
        colors = false
    }

    order += "volume master"
    order += "battery all"
    order += "tztime local"

    volume master {
        format = "󰕾 %volume"
        format_muted = "󰝟 %volume"
        device = "default"
    }

    battery all {
        format = "%status %percentage^fg()"
        status_chr = "^fg(2fed71)"
        status_bat = ""
        status_unk = "?"
        status_full = "^fg(2fed71)"
        status_idle = ""
        last_full_capacity = true
        threshold_type = percentage
        format_percentage = "%.00f%s"
        format_down = ""
    }

    tztime local {
        format = "󱑒 %I:%M %p"
    }
  '';

  configH = pkgs.writeText "config.h" ''
    #define MODKEY ${config.dwl.modkey}

    static const char *programsmenu[]    = { "${programsMenu}",  NULL };
    static const char *powermenu[]    = { "${powerMenu}",  NULL };

    ${builtins.readFile ./config.h}

    static const MonitorRule monrules[] = {
      ${config.dwl.monitor}
    };
  '';

  customDwlPackage =
    (pkgs-25-11.dwl.override {
      inherit configH;
    }).overrideAttrs
      (oldAttrs: {
        patches = (oldAttrs.patches or [ ]) ++ [
          ./cursortheme.patch
          ./restore-monitor.patch
        ];
        buildInputs = oldAttrs.buildInputs or [ ] ++ [
          pkgs.libdrm
          pkgs.fcft
        ];
      });

  swayIdle = wrappers.lib.wrapPackage {
    inherit pkgs;
    package = pkgs.swayidle;
    flags = {
      "-C" = toString (
        pkgs.writeText "config" ''
          before-sleep 'swaylock -f -c 000000'
        ''
      );
    };
  };

  dwlStartup = pkgs.writeScript "dwl-startup" ''
    #!/bin/sh
    dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=wlroots
    systemctl --user restart xdg-desktop-portal

    ${pkgs.xsetroot}/bin/xsetroot -cursor_name Bibata-Modern-Classic
    ${lib.getExe kanshi} &
    ${pkgs.i3status}/bin/i3status -c ${i3statusConfig} | ${pkgs.dwlb}/bin/dwlb -status-stdin all & ${pkgs.dwlb}/bin/dwlb -custom-title -font "monospace:size=14" &
    ${swayIdle}/bin/swayidle &
    ${pkgs.wbg}/bin/wbg ${./wallpaper.jpeg}
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
    hardware.graphics.extraPackages = [ pkgs.obs-studio-plugins.obs-vkcapture ];

    services.pipewire = {
      enable = true;
      pulse.enable = true;
    };

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet -t -c /run/current-system/sw/bin/dwl-wrapped";
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

    programs.dconf = {
      enable = true;
      profiles.user.databases = [
        {
          settings = {
            "org/gnome/desktop/interface" = {
              color-scheme = "prefer-dark";
              gtk-theme = "Adwaita-dark";
            };
          };
        }
      ];
    };

    qt = {
      enable = true;
      platformTheme = "gnome";
      style = "adwaita-dark";
    };

    environment.sessionVariables = {
      GTK_THEME = "Adwaita-dark";
      XDG_CURRENT_DESKTOP = "wlroots";
      XCURSOR_THEME = "Bibata-Modern-Classic"; # Replace with your exact Bibata variant name
      XCURSOR_SIZE = "24"; # Adjust size to your preference
    };

    environment.systemPackages = [
      pkgs.wbg
      pkgs.dwlb
      pkgs.i3status
      pkgs.wmenu
      pkgs.wl-clipboard
      pkgs.bibata-cursors
      pkgs.swaylock
      pkgs.slurp
      pkgs.grim
      pkgs.wlr-which-key
      pkgs.xsetroot
      pkgs.playerctl
      pkgs.brightnessctl
      swayIdle
      kanshi
    ];

    environment.etc = {
      "xdg/gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-theme-name = Adwaita-dark
        gtk-application-prefer-dark-theme = 1
        gtk-cursor-theme-name=Bibata-Modern-Classic
        gtk-cursor-theme-size=24
      '';
      "xdg/gtk-4.0/settings.ini".text = ''
        [Settings]
        gtk-theme-name = Adwaita-dark
        gtk-application-prefer-dark-theme = 1
        gtk-cursor-theme-name=Bibata-Modern-Classic
        gtk-cursor-theme-size=24
      '';
    };

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config = {
        common = {
          # Use wlr for everything it supports, fallback to gtk for themes/files
          default = [
            "wlr"
            "gtk"
          ];
          # Explicitly ensure the settings portal uses the gtk backend
          "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
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
