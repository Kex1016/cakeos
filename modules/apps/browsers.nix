{ inputs, ... }:
{
  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      imports = [ inputs.zen-browser.homeModules.beta ];

      home.packages = with pkgs; [
        firefoxpwa
      ];

      programs.chromium = {
        enable = true;
        extensions = [
          # TODO: Add extensions
        ];
        # TODO: Add policies
      };

      programs.zen-browser = {
        enable = true;
        nativeMessagingHosts = [ pkgs.firefoxpwa ];
        policies = {
          AutofillAddressEnabled = true;
          AutofillCreditCardEnabled = false;
          DisableAppUpdate = true;
          DisableFeedbackCommands = true;
          DisableFirefoxStudies = true;
          DisablePocket = true;
          DisableTelemetry = true;
          DontCheckDefaultBrowser = true;
          NoDefaultBookmarks = true;
          OfferToSaveLogins = false;
          EnableTrackingProtection = {
            Value = true;
            Locked = true;
            Cryptomining = true;
            Fingerprinting = true;
          };
        };
        profiles.default.settings = {
          browser = {
            tabs.warnOnClose = false;
          };
        };
        profiles.default.extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          adnauseam
          keepassxc-browser
          tampermonkey
          stylus
          shinigami-eyes
          augmented-steam
          sponsorblock
          karakeep
          enhanced-github
          github-file-icons
          consent-o-matic
          decentraleyes
          clearurls
          canvasblocker
          indie-wiki-buddy
          seventv
          themesong-for-youtube-music
          improved-tube
          redirect-shorts-to-youtube
          return-youtube-dislikes
        ];
        profiles.default.search = {
          force = true;
          default = "kagi";
          engines = {
            kagi = {
              name = "Kagi";
              urls = [
                {
                  template = "https://kagi.com/search?q={searchTerms}";
                  params = [
                    {
                      name = "query";
                      value = "searchTerms";
                    }
                  ];
                }
              ];

              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@k" ];
            };
            mynixos = {
              name = "My NixOS";
              urls = [
                {
                  template = "https://mynixos.com/search?q={searchTerms}";
                  params = [
                    {
                      name = "query";
                      value = "searchTerms";
                    }
                  ];
                }
              ];

              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@nx" ];
            };
          };
        };
      };
    };
}
