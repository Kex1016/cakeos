pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.modules.common.widgets.haiiro as H

// What the installer is about to write, as the gen/cakeos.nix it writes
// (backend.sh), with the passwords left out.
Page {
    id: page

    readonly property var disk: Installer.disks.find(d => d.path === Installer.disk) ?? ({
            model: "",
            size: ""
        })
    function str(s) {
        return "\"" + s + "\"";
    }
    function list(xs) {
        return "[ " + xs.map(x => str(x)).join(" ") + (xs.length ? " " : "") + "]";
    }
    readonly property var nix: ["# disko: " + Installer.disk + (page.disk.model ? ", " + page.disk.model : "") + (page.disk.size ? ", " + page.disk.size : "") + ", swap " + Installer.swapSize, "networking.hostName = " + str(Installer.hostname) + ";", "users.users." + Installer.username + ".isNormalUser = true;", "cakeos = {", "  desktop = " + str(Installer.desktop) + ";", "  primaryUser = " + str(Installer.username) + ";", "  autoLogin = " + Installer.autoLogin + ";", ...(Installer.mainframe ? ["  mainframe.enable = true;", "  mainframe.linkSsh = " + Installer.mainframeSsh + ";"] : []), "  kernel = " + str(Installer.kernel) + ";", "  timeZone = " + str(Installer.timeZone) + ";", "  keyboardLayouts = " + list(Installer.keyboardLayouts()) + ";", "  groups = " + list(Installer.groups) + ";", "  hardware = " + list(Installer.hardware) + ";", "};", ...(Installer.ramGb > 16 && Installer.tmpfsTmp ? ["fileSystems.\"/tmp\".fsType = \"tmpfs\";", "fileSystems.\"/var/cache\".fsType = \"tmpfs\";"] : []), ...(Installer.ramGb > 16 && Installer.tmpfsEtc ? ["fileSystems.\"/etc\".fsType = \"tmpfs\";"] : [])]

    function esc(s) {
        return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/ /g, "&nbsp;");
    }
    function paint(c, s) {
        return "<font color=\"" + c + "\">" + esc(s) + "</font>";
    }
    // comments muted, names in text, strings foam, true/false gold
    function styled(line) {
        if (line.startsWith("#"))
            return paint(H.HTokens.muted, line);
        const m = line.match(/^(\s*)([^=]+?)( = )(.*?)(;?)$/);
        if (!m)
            return paint(H.HTokens.subtle, line);
        let value = "", at = 0, t;
        const tokens = /"[^"]*"|\btrue\b|\bfalse\b/g;
        while ((t = tokens.exec(m[4])) !== null) {
            value += paint(H.HTokens.subtle, m[4].slice(at, t.index)) + paint(t[0].startsWith("\"") ? H.HTokens.foam : H.HTokens.gold, t[0]);
            at = t.index + t[0].length;
        }
        value += paint(H.HTokens.subtle, m[4].slice(at));
        return esc(m[1]) + paint(H.HTokens.text, m[2]) + paint(H.HTokens.muted, m[3]) + value + paint(H.HTokens.muted, m[5]);
    }

    label: "cat gen/cakeos.nix"
    variant: "gold"
    note: "written to /mnt/etc/cakeos/gen/cakeos.nix"

    Line {
        ink: "rose"
        text: "Last look. Nothing has been touched yet, and you can still go back and change any of it."
    }
    Gap {
        size: 12
    }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: code.implicitHeight + 16
        color: H.HTokens.base

        Column {
            id: code
            x: 12
            y: 8
            width: parent.width - 24
            spacing: 2
            Repeater {
                model: page.nix
                H.HText {
                    required property string modelData
                    width: code.width
                    text: page.styled(modelData)
                    textFormat: Text.StyledText
                    role: "code"
                    elide: Text.ElideRight
                }
            }
        }
    }
    Gap {
        size: 12
    }
    Line {
        ink: "love"
        text: "Installing erases everything on " + Installer.disk + (page.disk.model ? " (" + page.disk.model + ")" : "") + "."
    }
}
