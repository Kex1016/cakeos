{ ... }:

{
  # Each of these gates itself on `osConfig.cakeos.desktop`, so importing the
  # whole desktop is harmless when another one is selected.
  imports = [
    ./dconf.nix
    ./theme.nix
    ./mime.nix
    ./terminal.nix
    ./groups.nix
  ];
}
