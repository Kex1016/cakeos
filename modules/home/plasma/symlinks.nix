{ config, ... }:

let
  dotfiles = "${config.home.homeDirectory}/NixOS/dots/.config";
  # binfiles = "${config.home.homeDirectory}/NixOS/dots/.local/bin";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
  configs = { }; # no need ofr this yet
in
{
  # bins
  home.file.".local/bin" = {
    source = ../../../../dots/.local/bin;
    recursive = true;
    executable = true;
  };

  home.file.".local/share/rofi/icons" = {
    source = ../../../../extra/icons;
    recursive = true;
  };

  home.file.".cakepics" = {
    source = ../../../../extra/pics;
    recursive = true;
  };

  home.file.".bashrc" = {
    source = ../../../../dots/.bashrc;
  };

  # dots
  xdg.configFile = builtins.mapAttrs (name: subpath: {
    source = create_symlink "${dotfiles}/${subpath}";
    recursive = true;
  }) configs;
}
