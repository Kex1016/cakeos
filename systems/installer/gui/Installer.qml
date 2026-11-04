pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Every answer, and the backend (cake-install-backend.sh) that probes the
// machine and runs the install. The text installer drives the same backend.
Singleton {
    id: root

    readonly property string backend: Quickshell.env("CAKEOS_INSTALLER_BACKEND") || "/etc/cake-install-backend.sh"
    readonly property string runDir: Quickshell.env("CAKEOS_INSTALLER_RUN") || "/run/cakeos-installer"

    property bool probing: true
    property bool online: false
    property bool hasWifi: false
    property int ramGb: 0
    property var disks: []
    property var desktops: []
    property var timezones: []

    property string disk: ""
    property string desktop: ""
    property string hostname: "cakeos"
    property string username: "cakeos"
    property string userPassword: ""
    property string userPasswordConfirm: ""
    property string rootPassword: ""
    property string rootPasswordConfirm: ""
    property bool autoLogin: false
    property string mainframeDevice: ""
    property bool mainframe: false
    property bool mainframeSsh: false
    property string timeZone: "Europe/Budapest"
    property var layouts: ["us"]
    property bool huQwerty: true
    property var groups: []
    property var hardware: []
    property string kernel: "latest"
    property string swapSize: ""
    property bool tmpfsTmp: false
    property bool tmpfsEtc: false

    readonly property var layoutChoices: ["us", "hu", "de", "fr", "es", "it", "pl", "cz", "sk", "ro", "hr", "si", "rs", "gb", "dk", "no", "se", "fi", "nl", "pt", "tr", "ru", "ua", "jp", "kr"]
    readonly property var groupChoices: [
        { id: "gaming", name: "Gaming", icon: "sports_esports", description: "Steam, Proton, gamescope, Prism Launcher, mod managers" },
        { id: "creative", name: "Creative", icon: "palette", description: "OBS Studio, Blockbench, draw.io, screen recording" },
        { id: "development", name: "Development", icon: "code", description: "VSCodium, Neovim, JetBrains IDEA, toolchains, language servers" },
        { id: "office", name: "Office", icon: "work", description: "OnlyOffice, Teams, Proton Pass, mail, Synology Drive" },
        { id: "communication", name: "Communication", icon: "forum", description: "Discord (Vesktop)" },
        { id: "media", name: "Media", icon: "music_note", description: "Spotify with Spicetify, Plexamp" },
        { id: "flatpak", name: "Flatpak", icon: "deployed_code", description: "TeamSpeak, Tauon, HandBrake, Stremio, Karere" }
    ]
    readonly property var hardwareChoices: [
        { id: "tablet", name: "Drawing tablets", icon: "draw", description: "OpenTabletDriver" },
        { id: "airpods", name: "AirPods", icon: "earbuds", description: "LibrePods for AirPods controls" },
        { id: "vpn", name: "VPN", icon: "vpn_lock", description: "Mullvad VPN client" }
    ]
    readonly property var kernelChoices: [
        { id: "latest", name: "Latest", icon: "bolt", description: "Newest mainline kernel" },
        { id: "cachyos", name: "CachyOS", icon: "speed", description: "Scheduler-patched, better desktop and game latency" },
        { id: "lts", name: "LTS", icon: "shield", description: "Long-term support, most conservative" }
    ]

    readonly property bool hostnameValid: /^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}$/.test(hostname)
    readonly property bool usernameValid: /^[a-z_][a-z0-9_-]{0,31}$/.test(username)
    readonly property bool swapValid: /^[0-9]+[GM]$/.test(swapSize)
    readonly property bool accountValid: hostnameValid && usernameValid && userPassword.length > 0 && userPassword === userPasswordConfirm && rootPassword.length > 0 && rootPassword === rootPasswordConfirm

    function toggled(list, id, on) {
        const rest = list.filter(x => x !== id);
        return on ? rest.concat([id]) : rest;
    }

    function keyboardLayouts() {
        return layouts.map(l => l === "hu" && huQwerty ? "hu+qwerty" : l);
    }

    // ── Probing ──────────────────────────────────────────────

    function refresh() {
        probing = true;
        probeProc.running = true;
    }

    Process {
        id: probeProc
        command: [root.backend, "probe"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const p = JSON.parse(text);
                    root.online = p.online;
                    root.hasWifi = p.wifi;
                    root.ramGb = p.ramGb;
                    root.disks = p.disks;
                    root.desktops = p.desktops;
                    if (root.swapSize === "")
                        root.swapSize = p.swapDefault;
                    if (root.disks.length === 1 && root.disk === "")
                        root.disk = root.disks[0].path;
                } catch (e) {
                    console.warn("probe failed:", e, text);
                }
                root.probing = false;
            }
        }
    }

    Process {
        command: [root.backend, "timezones"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.timezones = text.split("\n").filter(z => z.length > 0)
        }
    }

    onUsernameChanged: mainframeTimer.restart()
    onDiskChanged: mainframeTimer.restart()

    Timer {
        id: mainframeTimer
        interval: 400
        onTriggered: mainframeProc.running = true
    }

    Process {
        id: mainframeProc
        command: [root.backend, "mainframe", root.username, root.disk]
        stdout: StdioCollector {
            onStreamFinished: {
                root.mainframeDevice = text.trim();
                if (root.mainframeDevice === "")
                    root.mainframe = false;
            }
        }
    }

    // ── Wi-Fi ────────────────────────────────────────────────

    property var networks: []
    property bool scanning: false
    property bool connecting: false
    property string wifiError: ""

    function scanWifi() {
        scanning = true;
        wifiError = "";
        scanProc.running = true;
    }

    function connectWifi(ssid, password) {
        connecting = true;
        wifiError = "";
        connectProc.password = password;
        connectProc.command = [backend, "wifi-connect", ssid];
        connectProc.running = true;
    }

    Process {
        id: scanProc
        command: [root.backend, "wifi-scan"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.networks = text.split("\n").filter(s => s.length > 0);
                root.scanning = false;
                if (root.networks.length === 0)
                    root.wifiError = "No networks found.";
            }
        }
    }

    Process {
        id: connectProc
        property string password
        stdinEnabled: true
        stderr: StdioCollector {
            id: connectErr
        }
        onStarted: {
            write(password + "\n");
            password = "";
        }
        onExited: code => {
            root.connecting = false;
            if (code === 0) {
                root.online = true;
            } else {
                root.wifiError = connectErr.text.trim() || "Could not connect.";
            }
        }
    }

    // ── Install ──────────────────────────────────────────────

    // idle, running, done or failed
    property string phase: "idle"
    property string stage: ""
    property var stagesDone: []
    property string status: ""
    property var log: []
    property string crashReport: ""
    property string error: ""

    readonly property var stages: [
        { id: "partition", name: "Partition the disk" },
        { id: "copy", name: "Copy CakeOS" },
        { id: "hardware", name: "Detect hardware" },
        { id: "config", name: "Write your configuration" },
        { id: "build", name: "Build and install the system" }
    ]

    function answers() {
        return {
            disk: disk,
            desktop: desktop,
            hostname: hostname,
            username: username,
            userPassword: userPassword,
            rootPassword: rootPassword,
            autoLogin: autoLogin,
            mainframe: {
                enable: mainframe,
                device: mainframe ? "/dev/disk/by-label/" + (Quickshell.env("MAINFRAME_LABEL") || "Large") : "",
                linkSsh: mainframe && mainframeSsh
            },
            timeZone: timeZone,
            keyboardLayouts: keyboardLayouts(),
            groups: groups,
            hardware: hardware,
            kernel: kernel,
            swapSize: swapSize,
            tmpfs: {
                tmp: ramGb > 16 && tmpfsTmp,
                etc: ramGb > 16 && tmpfsEtc
            }
        };
    }

    function install() {
        phase = "running";
        stage = "";
        stagesDone = [];
        log = [];
        error = "";
        answersFile.setText(JSON.stringify(answers()));
        installProc.running = true;
    }

    FileView {
        id: answersFile
        path: root.runDir + "/answers.json"
        blockWrites: true
        preload: false
        printErrors: false
    }

    Process {
        id: installProc
        command: [root.backend, "install", root.runDir + "/answers.json"]
        stdout: SplitParser {
            onRead: line => root.consume(line)
        }
        stderr: SplitParser {
            onRead: line => root.consume(line)
        }
        onExited: code => {
            if (code === 0) {
                root.phase = "done";
            } else {
                root.phase = "failed";
                if (root.error === "")
                    root.error = "The installer stopped with status " + code + ".";
            }
        }
    }

    function consume(line) {
        if (line.startsWith("::stage ")) {
            const rest = line.slice(8);
            const id = rest.split(" ")[0];
            if (stage !== "")
                stagesDone = stagesDone.concat([stage]);
            stage = id;
            status = rest.slice(id.length + 1);
            return;
        }
        if (line.startsWith("::crash ")) {
            crashReport = line.slice(8);
            return;
        }
        if (line.startsWith("::error ")) {
            error = line.slice(8);
            return;
        }
        if (/^\[[0-9]/.test(line))
            status = line;
        log = log.concat([line]).slice(-400);
    }

    // ── Leaving ──────────────────────────────────────────────

    FileView {
        id: nextFile
        path: root.runDir + "/next"
        blockWrites: true
        preload: false
        printErrors: false
    }

    // The launcher reads this after the window closes: "tui" starts the text
    // installer, "shell" leaves a root prompt.
    function leave(next) {
        nextFile.setText(next);
        Qt.quit();
    }

    function reboot() {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }
}
