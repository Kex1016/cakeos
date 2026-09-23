{ pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      nerd-fonts.departure-mono
      nerd-fonts.symbols-only
      nerd-fonts.fantasque-sans-mono
      nerd-fonts.caskaydia-cove
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-lgc-plus
      noto-fonts-color-emoji
      roboto-flex
      roboto-slab
      roboto-mono
      nerd-fonts.roboto-mono
      liberation_ttf
      adwaita-fonts
    ];

    # Was implicit in ~/.config/fontconfig; declared here so it survives a
    # reinstall and matches the GNOME interface fonts set in
    # modules/home/gnome/dconf.nix.
    fontconfig.defaultFonts = {
      sansSerif = [
        "Roboto Flex"
        "Noto Sans"
      ];
      serif = [
        "Roboto Slab"
        "Noto Serif"
      ];
      monospace = [
        "CaskaydiaCove Nerd Font Mono"
        "Noto Sans Mono"
      ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
