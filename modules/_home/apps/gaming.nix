{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    prismlauncher
    r2modman
    osu-lazer-bin
    xivlauncher
    protonplus
    etterna
    #(pkgs.nexusmods-app.override { _7zz = pkgs._7zz-rar; })
    ocelot-desktop
    #inputs.hytale-launcher.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
