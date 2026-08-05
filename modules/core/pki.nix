{
  flake.modules.nixos.base = {
    # Path is relative to THIS file. home_root.crt lives at the repo root, so
    # this is two levels up -- it was `./home_root.crt` when the declaration
    # lived in system.nix at the root.
    security.pki.certificateFiles = [ ../../home_root.crt ];
  };
}
