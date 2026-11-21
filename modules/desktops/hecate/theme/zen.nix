{
  lib,
  osConfig,
  inputs,
  ...
}:

# Zen Browser in haiiro: hecate's fixed Zen templates on the default profile.
# The autoconfig script cuts Zen's own scripted motion; web pages keep their
# real prefers-reduced-motion.
let
  zen = "${inputs.hecate}/nix/haiiro/zen";
in
{
  config = lib.mkIf (osConfig.cakeos.desktop == "hecate") {
    programs.zen-browser = {
      extraPrefsFiles = [ "${zen}/motion.cfg.js" ];
      profiles.default = {
        userChrome = builtins.readFile "${zen}/userChrome.css";
        userContent = builtins.readFile "${zen}/userContent.css";
        settings = import "${zen}/prefs.nix";
        mods = [
          # Better CtrlTab Panel, styled by the haiiro userChrome
          "72f8f48d-86b9-4487-acea-eb4977b18f21"
          # No Top Sites
          "e122b5d9-d385-4bf8-9971-e137809097d0"
        ];
      };
    };
  };
}
