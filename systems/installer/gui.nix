# The graphical installer: gui/ (Quickshell) in cage, on the CakeOS palette and
# wallpaper from theme/. It drives the same backend as install-tui.sh, which is
# still there as the fallback and behind "Text installer".
{ pkgs, ... }:
let
  theme = import ../../theme { inherit pkgs; };

  gui = pkgs.runCommand "cakeos-installer-gui" { } ''
    cp -r ${./gui} $out
    chmod -R u+w $out
    cp ${theme.colorsJson} $out/colors.json
    cp ${theme.wallpaper} $out/wallpaper.png
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

      status=0
      if compgen -G "/dev/dri/card*" >/dev/null; then
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

  fonts.packages = with pkgs; [
    rubik
    material-symbols
    nerd-fonts.jetbrains-mono
  ];
}
