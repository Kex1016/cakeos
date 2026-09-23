{ lib, ... }:

{
  # Install-time choices. The installer TUI writes these into
  # gen/<config>.nix; optional modules gate themselves on them so a machine
  # only carries what was actually picked.
  #
  # Home-manager modules read the same values through `osConfig.cakeos.*`.
  options.cakeos = {
    groups = lib.mkOption {
      type = lib.types.listOf (
        lib.types.enum [
          "gaming"
          "creative"
          "development"
          "office"
          "communication"
          "media"
          "flatpak"
        ]
      );
      default = [ ];
      example = [
        "gaming"
        "development"
      ];
      description = "Optional package groups selected during installation.";
    };

    hardware = lib.mkOption {
      type = lib.types.listOf (
        lib.types.enum [
          "tablet"
          "airpods"
          "vpn"
        ]
      );
      default = [ ];
      example = [ "tablet" ];
      description = "Optional hardware/service support selected during installation.";
    };

    kernel = lib.mkOption {
      type = lib.types.enum [
        "latest"
        "cachyos"
        "lts"
      ];
      default = "latest";
      description = ''
        Which kernel to boot.

        - `latest`  newest mainline (pkgs.linuxPackages_latest)
        - `cachyos` scheduler-patched build; needs the lantian binary cache
        - `lts`     long-term support (pkgs.linuxPackages), most conservative

        The mapping lives in systems/cakeos/configuration.nix.
      '';
    };

    primaryUser = lib.mkOption {
      type = lib.types.str;
      default = "cakeos";
      description = "The account created at install time.";
    };

    autoLogin = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Log the primary user straight into GNOME without a GDM prompt.";
    };

    timeZone = lib.mkOption {
      type = lib.types.str;
      default = "Europe/Budapest";
      example = "UTC";
      description = "System time zone.";
    };

    keyboardLayouts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "us"
        "hu+qwerty"
      ];
      example = [ "us" ];
      description = ''
        XKB layouts, in priority order. Entries may carry a variant using the
        `layout+variant` form, e.g. "hu+qwerty". Used for both the console and
        the GNOME input sources.
      '';
    };
  };
}
