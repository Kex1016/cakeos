# Per-desktop runtime state, for `scripts/cakeos-wm`: `{ <desktop> = { paths;
# dconf; }; }`, from each desktop's optional state.nix. Plain Nix with no
# arguments, so the script can read it with `nix eval --json --file`.
let
  empty = {
    paths = [ ];
    dconf = [ ];
  };
  stateOf =
    d:
    let
      file = ./. + "/${d}/state.nix";
    in
    empty // (if builtins.pathExists file then import file else { });
in
builtins.listToAttrs (
  map (d: {
    name = d;
    value = stateOf d;
  }) (import ./list.nix)
)
