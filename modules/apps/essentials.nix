{ inputs, ... }:
{
  flake.modules.homeManager.base =
    { pkgs, ... }:
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      imports = [ inputs.spicetify-nix.homeManagerModules.default ];

      home.packages = with pkgs; [
        pavucontrol
        gnome-font-viewer
        qpwgraph
        inotify-tools
        file
        jetbrains.idea-oss
        yubioath-flutter
        easyeffects
        onlyoffice-desktopeditors
      ];

      xdg.autostart.enable = true;

      programs = {
        mpv = {
          enable = true;
        };

        spicetify = {
          enable = true;
          enabledExtensions = with spicePkgs.extensions; [
            adblockify
            hidePodcasts
            shuffle
          ];
        };

        zathura = {
          enable = true;
        };

        keepassxc = {
          enable = true;
          autostart = true;
        };
      };

      services = {
        kdeconnect = {
          enable = true;
          indicator = true;
        };
        easyeffects = {
          enable = true;
        };
      };

      home.file.".local/bin" = {
        source = ../../scripts;
        recursive = true;
        executable = true;
      };

      home.sessionPath = [ "$HOME/.local/bin" ];
    };
}
