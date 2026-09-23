{
  lib,
  config,
  osConfig,
  ...
}:

let
  cfg = osConfig.cakeos.mainframe;

  # mkOutOfStoreSymlink points at a real path rather than copying into the
  # Nix store, which is what we want: these target a mounted disk whose
  # contents change independently of any rebuild.
  linkTo = name: {
    source = config.lib.file.mkOutOfStoreSymlink "${cfg.root}/${name}";
  };
in

lib.mkIf cfg.enable {
  home.file =
    lib.genAttrs cfg.links linkTo // lib.optionalAttrs cfg.linkSsh { ".ssh" = linkTo ".ssh"; };

  # `xdg.userDirs.createDirectories` would create Documents/, Downloads/ etc.
  # as real directories, which collides with the symlinks above. The dirs
  # exist on the data disk already, so there is nothing to create.
  xdg.userDirs.createDirectories = lib.mkForce false;

  # home-manager's ssh module writes ~/.ssh/config. With ~/.ssh symlinked to
  # the data disk that write lands *through* the link and clobbers the real
  # config file. The disk's copy wins instead.
  programs.ssh.enable = lib.mkIf cfg.linkSsh (lib.mkForce false);
}
