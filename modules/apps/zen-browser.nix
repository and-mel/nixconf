{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  config =
    let
      extension = shortId: guid: {
        name = guid;
        value = {
          install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
          installation_mode = "normal_installed";
        };
      };

      prefs = {
        # Check these out at about:config
        "extensions.autoDisableScopes" = 0;
        "extensions.pocket.enabled" = false;
        "browser.contextual-password-manager.enabled" = false;
        # ...
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

        # --- Declarative Zen Preferences ---
        # Accent color (matches your Gruvbox themes: #8ec07c)
        "zen.theme.accent-color" = "#8ec07c";

        # UI & Layout settings
        "zen.theme.gradient" = true;
        "zen.view.compact" = false;
        "zen.view.hide-window-controls" = true;

        "zen.glance.enabled" = false;

        # Tabs and Navigation
        "zen.urlbar.replace-newtab" = true;
        "zen.tabs.vertical.right-side" = false;
        "zen.tabs.show-newtab-vertical" = false;

        "signon.rememberSignons" = false;
        "signon.autofillForms" = false;
        "signon.generation.enabled" = false;
        "signon.management.page.enabled" = false;

        "permissions.default.shortcuts" = 3;
        "browser.tabs.unloadOnLowMemory" = true;
      };

      extensions = [
        # To add additional extensions, find it on addons.mozilla.org, find
        # the short ID in the url (like https://addons.mozilla.org/en-US/firefox/addon/!SHORT_ID!/)
        # Then go to https://addons.mozilla.org/api/v5/addons/addon/!SHORT_ID!/ to get the guid
        (extension "ublock-origin" "uBlock0@raymondhill.net")
        (extension "keepa" "amptra@keepa.com")
        (extension "keepassxc-browser" "keepassxc-browser@keepassxc.org")
        # ...
      ];

    in
    lib.mkIf config.apps.enable {
      environment.systemPackages = [
        (pkgs.wrapFirefox
          inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.zen-browser-unwrapped
          {
            extraPrefs = lib.concatLines (
              lib.mapAttrsToList (
                name: value: "lockPref(${lib.strings.toJSON name}, ${lib.strings.toJSON value});"
              ) prefs
            );

            extraPolicies = {
              DisableTelemetry = true;
              ExtensionSettings = builtins.listToAttrs extensions;

              SearchEngines = {
                Default = "ddg";
                Add = [
                  {
                    Name = "nixpkgs packages";
                    URLTemplate = "https://search.nixos.org/packages?query={searchTerms}";
                    IconURL = "https://wiki.nixos.org/favicon.ico";
                    Alias = "@np";
                  }
                  {
                    Name = "NixOS options";
                    URLTemplate = "https://search.nixos.org/options?query={searchTerms}";
                    IconURL = "https://wiki.nixos.org/favicon.ico";
                    Alias = "@no";
                  }
                  {
                    Name = "NixOS Wiki";
                    URLTemplate = "https://wiki.nixos.org/w/index.php?search={searchTerms}";
                    IconURL = "https://wiki.nixos.org/favicon.ico";
                    Alias = "@nw";
                  }
                ];
              };
            };
          }
        )
      ];
    };
}
