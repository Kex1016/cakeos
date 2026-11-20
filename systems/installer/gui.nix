# The graphical installer: gui/ (Quickshell) in cage, in haiiro. Its parts are
# hecate's haiiro kit, copied in from the hecate input rather than kept twice, and
# it is set in the same bundled fonts. It drives the same backend as
# install-tui.sh, which is still there as the fallback and behind "text installer".
{ pkgs, inputs, ... }:
let
  hecate = inputs.hecate;

  # IBM VGA 8x16, Jacquard 24 and the Unifont fallback, with their fontconfig order.
  haiiroFonts =
    hecate.packages.${pkgs.stdenv.hostPlatform.system}.haiiro-fonts
      or (pkgs.callPackage "${hecate}/nix/fonts.nix" { });

  # gui/ imports the kit as qs.modules.common.widgets.haiiro, so it goes where
  # the shell keeps it. gui/modules/common/Appearance.qml stands in for the
  # shell's token source.
  gui = pkgs.runCommand "cakeos-installer-gui" { } ''
    cp -r ${./gui} $out
    chmod -R u+w $out
    mkdir -p $out/modules/common/widgets
    cp -r ${hecate}/shell/end4-pC/modules/common/widgets/haiiro $out/modules/common/widgets/haiiro
    chmod -R u+w $out/modules/common/widgets/haiiro
    rm -f $out/modules/common/widgets/haiiro/Gallery.qml
  '';

  launcher = pkgs.writeShellApplication {
    name = "cake-install-gui";
    runtimeInputs = [
      pkgs.cage
      pkgs.quickshell
      pkgs.coreutils
    ];
    text = ''
      rm -f /run/cakeos-installer-stopped
      run=/run/cakeos-installer
      mkdir -p "$run"
      chmod 700 "$run"
      rm -f "$run/next"
      export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      mkdir -p "$XDG_RUNTIME_DIR"
      chmod 700 "$XDG_RUNTIME_DIR"
      export QT_QPA_PLATFORM=wayland

      gui() {
        cage -s -d -m last -- quickshell --no-duplicate -p ${gui}/shell.qml >> /var/log/cake-installer-gui.log 2>&1
      }

      # tty1 can log in before the GPU driver has loaded.
      has_drm() {
        local card
        for card in /dev/dri/card*; do
          [ -e "$card" ] && return 0
        done
        return 1
      }
      for _ in $(seq 1 10); do
        has_drm && break
        sleep 1
      done

      status=0
      if has_drm; then
        start=$(date +%s)
        gui || status=$?
        # No usable GL (a VM without virgl, an unsupported GPU): draw in software.
        if [ "$status" -ne 0 ] && [ ! -e "$run/next" ] && [ $(( $(date +%s) - start )) -lt 15 ]; then
          status=0
          WLR_RENDERER=pixman QT_QUICK_BACKEND=software gui || status=$?
        fi
      else
        status=1
      fi

      case "$(cat "$run/next" 2>/dev/null)" in
        shell)
          touch /run/cakeos-installer-stopped
          printf '\nStart the installer again with:  cake-install-gui  (or cake-install for the text one)\n\n'
          ;;
        tui)
          exec /etc/cake-install.sh
          ;;
        *)
          if [ "$status" -ne 0 ]; then
            echo "The graphical installer could not start (see /var/log/cake-installer-gui.log)."
            echo "Starting the text installer instead."
            sleep 2
            exec /etc/cake-install.sh
          fi
          ;;
      esac
    '';
  };
in
{
  environment.systemPackages = [ launcher ];

  hardware.graphics.enable = true;

  fonts.packages = [ haiiroFonts ];
  fonts.fontconfig.confPackages = [ haiiroFonts ];
}
