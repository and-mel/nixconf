{ lib, config, pkgs, ... }: {
  config = lib.mkIf config.apps.enable {
    programs.firefox = {
      enable = true;
      package = pkgs.librewolf;
      wrapperConfig = {
        speechSynthesisSupport = false;
      };
      preferencesStatus = "locked";
      policies = {
        "FirefoxDefaultTheme" = "dark";
      };
      preferences = {
        "browser.uiCustomization.state" = ''
          {
            "placements": {
              "widget-overflow-fixed-list":[],
              "unified-extensions-area": [
                "canvasblocker_kkapsner_de-browser-action",
                "_762f9885-5a13-4abd-9c77-433dcd38b8fd_-browser-action"
              ],
              "nav-bar": [
                "back-button",
                "forward-button",
                "stop-reload-button",
                "customizableui-special-spring1",
                "vertical-spacer",
                "urlbar-container",
                "customizableui-special-spring2",
                "downloads-button","fxa-toolbar-menu-button",
                "unified-extensions-button",
                "ublock0_raymondhill_net-browser-action"
              ],
              "toolbar-menubar": ["menubar-items"],
              "TabsToolbar": ["tabbrowser-tabs","new-tab-button","alltabs-button"],
              "vertical-tabs": [],
              "PersonalToolbar": ["personal-bookmarks"]
            },
            "seen": [
              "developer-button",
              "ublock0_raymondhill_net-browser-action",
              "canvasblocker_kkapsner_de-browser-action",
              "_762f9885-5a13-4abd-9c77-433dcd38b8fd_-browser-action",
              "screenshot-button"
            ],
            "dirtyAreaCache": [
              "nav-bar",
              "vertical-tabs",
              "PersonalToolbar",
              "toolbar-menubar",
              "TabsToolbar",
              "unified-extensions-area"
            ],"currentVersion":23,
            "newElementCount":2
          }
        '';

        "layout.css.prefers-color-scheme.content-override" = 0;
        "webgl.disabled" = false;
        "privacy.clearHistory.cookiesAndStorage" = false;
        "privacy.clearSiteData.cookiesAndStorage" = false;
        "privacy.clearOnShutdown_v2.cookiesAndStorage" = false;
        "privacy.clearOnShutdown.cookies" = false;
        "privacy.fingerprintingProtection" = true;
        "privacy.resistFingerprinting" = false;
      };
    };
  };
}
