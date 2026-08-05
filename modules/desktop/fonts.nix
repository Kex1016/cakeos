{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      fonts.packages = with pkgs; [
        nerd-fonts.departure-mono
        nerd-fonts.symbols-only
        nerd-fonts.fantasque-sans-mono
        nerd-fonts.caskaydia-cove
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-lgc-plus
        roboto-flex
        roboto-slab
        roboto-mono
        nerd-fonts.roboto-mono
        liberation_ttf
      ];
    };
}
