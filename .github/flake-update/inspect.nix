# Summarises one evaluated CakeOS configuration for the flake update report (report.py):
#   packages: name -> versions, for what is installed (system, users, Home Manager, fonts,
#             the kernel)
#   options:  every `*.enable` that is on, and every `*.package` of an enabled module
#             (services.pipewire.package, programs.steam.package, ...), as "name version"
#   warnings: the configuration's evaluation warnings
# Used as `nix eval --impure --json <flake>#nixosConfigurations.cakeos --apply 'import inspect.nix'`.
system:
let
  inherit (system) config options pkgs;
  inherit (pkgs) lib;

  try =
    x:
    let
      r = builtins.tryEval x;
    in
    if r.success then r.value else null;

  describe =
    p:
    try (
      if lib.isDerivation p then
        let
          v = lib.getVersion p;
        in
        builtins.deepSeq v "${lib.getName p}${lib.optionalString (v != "") " ${v}"}"
      else if p == null then
        "none"
      else if builtins.isList p then
        lib.concatMapStringsSep ", " (x: if lib.isDerivation x then lib.getName x else "?") p
      else
        null
    );

  packageEntry =
    p:
    let
      e = try (
        if lib.isDerivation p then
          builtins.deepSeq [ (lib.getName p) (lib.getVersion p) ] {
            name = lib.getName p;
            version = lib.getVersion p;
          }
        else
          null
      );
    in
    lib.optional (e != null) e;

  tryList =
    l:
    let
      r = try (builtins.seq (builtins.length l) l);
    in
    if r == null then [ ] else r;

  hmUsers = lib.attrValues (config.home-manager.users or { });
  installed =
    tryList config.environment.systemPackages
    ++ lib.concatMap (u: tryList (u.packages or [ ])) (lib.attrValues config.users.users)
    ++ lib.concatMap (u: tryList u.home.packages) hmUsers
    ++ tryList config.fonts.packages
    ++ [ config.boot.kernelPackages.kernel ];

  packages = lib.mapAttrs (
    _: es: lib.concatStringsSep ", " (lib.unique (lib.sort (a: b: a < b) (map (e: e.version) es)))
  ) (lib.groupBy (e: e.name) (lib.concatMap packageEntry installed));

  # Every option of an enabled module, as { path, opt }: a set with an `enable` option is only
  # descended into when that is on (a disabled module's defaults can fail in ways tryEval can't
  # catch). Option sets that are options themselves (attrsOf submodule: fileSystems,
  # systemd.services, home-manager.users) are leaves. `skip` holds trees whose values only
  # evaluate on matching hardware (nvidia's need an nvidia package).
  skip = [ "hardware.nvidia" ];
  # A hidden `enable` is a renamed alias: reading it warns (or aborts), and the module lives
  # at the new path anyway.
  isOn =
    o:
    lib.isOption (o.enable or null)
    && (o.enable.visible or true) != false
    && try (o.enable.value == true) == true;
  walk =
    path: o:
    if lib.elem (lib.concatStringsSep "." path) skip then
      [ ]
    else if lib.isOption o then
      [
        {
          inherit path;
          opt = o;
        }
      ]
    else if builtins.isAttrs o && (lib.isOption (o.enable or null) -> isOn o) then
      lib.concatLists (
        lib.mapAttrsToList (
          n: v:
          if n == "_module" then
            [ ]
          else
            let
              r = try (builtins.seq (walk (path ++ [ n ]) v) (walk (path ++ [ n ]) v));
            in
            if r == null then [ ] else r
        ) o
      )
    else
      [ ];
  # Only options something sets, and not renamed ones (hidden aliases that warn when read).
  all = lib.filter (
    { opt, ... }:
    (opt.visible or true) != false && try ((opt.definitionsWithLocations or [ ]) != [ ]) == true
  ) (walk [ ] options);
  enabled = lib.listToAttrs (
    lib.concatMap (
      { path, opt }:
      lib.optional (lib.last path == "enable" && try (opt.value == true) == true) {
        name = lib.concatStringsSep "." path;
        value = true;
      }
    ) all
  );
  modulePackages = lib.listToAttrs (
    lib.concatMap (
      { path, opt }:
      let
        prefix = lib.init path;
        on = enabled ? ${lib.concatStringsSep "." (prefix ++ [ "enable" ])};
        value = if lib.last path == "package" && on then describe (try opt.value) else null;
      in
      lib.optional (value != null) {
        name = lib.concatStringsSep "." path;
        inherit value;
      }
    ) all
  );
in
{
  inherit packages;
  options = lib.mapAttrs (_: _: "on") enabled // modulePackages;
  warnings =
    let
      w = try (builtins.deepSeq config.warnings config.warnings);
    in
    if w == null then [ ] else w;
}
