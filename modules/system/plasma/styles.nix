{ pkgs, inputs, ... }:
{
  environment.systemPackages = [
    pkgs.kdePackages.qtstyleplugin-kvantum
    pkgs.kdePackages.oxygen
    pkgs.kdePackages.oxygen-icons
    pkgs.kdePackages.oxygen-sounds
  ];

  programs.qylock = {
    enable = true;
    theme = "enfield"; # any directory name under themes/
    sddm.enable = true;             # installs theme + sets it active (default)
    quickshell.enable = false;       # adds `qylock-lock` to PATH (default)

    # Optional per-theme tweaks (replaces the interactive prompts):
    # themeOptions = {
    #   terraria.backgroundMode = "time"; # time | random | static
    #   Genshin.backgroundMode = "time";
    #   clockwork.orbital = {
    #     themeMode = "dark";
    #     enableWindup = true;
    #   };
    #   osu.gameMode = "menu"; # menu | game
    # };
  };
}
