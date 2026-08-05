# programs.appimage.binfmt registers appimage_type_1 and appimage_type_2.
# system.nix used to ALSO hand-roll a third registration named `appimage` whose
# magic was identical to type 2. That was never a module-system conflict, since
# the attribute names differ -- just a duplicate kernel binfmt entry. Removed.
{
  flake.modules.nixos.base = {
    programs.appimage = {
      enable = true;
      binfmt = true;
    };
  };
}
