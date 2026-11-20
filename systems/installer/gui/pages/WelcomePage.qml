pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.modules.common.widgets.haiiro as H

Page {
    id: page

    property string ssid: ""

    label: "cake-install: hello"

    Line {
        ink: "rose"
        text: "The computer hums. A disk is about to become CakeOS."
    }
    Gap {}
    Line {
        text: "This installer erases one disk, sets CakeOS up on it and builds your system there. Most of the system is downloaded while it runs, so it wants a connection."
    }

    Heading {
        text: "connection"
    }
    H.SettingRow {
        Layout.fillWidth: true
        name: "internet"
        description: Installer.probing ? "Looking for a way out." : Installer.online ? "Connected. The binary cache is reachable." : Installer.hasWifi ? "No connection yet. Pick a network below, or plug in a cable and look again." : "No connection and no Wi-Fi adapter. Plug in a cable and look again."
        H.Chip {
            on: Installer.online
            text: Installer.probing ? "checking" : Installer.online ? "online" : "offline"
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: !Installer.probing && !Installer.online && Installer.hasWifi
        spacing: 0

        H.HLabel {
            Layout.topMargin: 10
            Layout.bottomMargin: 4
            text: "networks"
            visible: Installer.networks.length > 0
        }
        ChoiceList {
            model: Installer.networks.map(n => ({
                        key: n,
                        title: n
                    }))
            current: page.ssid
            onChosen: key => {
                page.ssid = key;
                wifiPassword.focusInput();
            }
        }
        Field {
            id: wifiPassword
            Layout.topMargin: 8
            visible: page.ssid !== ""
            user: page.ssid
            label: "password"
            password: true
            error: Installer.wifiError
            onAccepted: Installer.connectWifi(page.ssid, text)
        }
        Line {
            visible: page.ssid === "" && Installer.wifiError !== ""
            Layout.topMargin: 6
            role: "caption"
            ink: "love"
            text: Installer.wifiError
        }
    }

    Buttons {
        visible: !Installer.probing && !Installer.online
        H.InkButton {
            visible: Installer.hasWifi
            text: Installer.scanning ? "scanning…" : Installer.networks.length > 0 ? "scan again" : "scan for networks"
            ink: Installer.networks.length > 0 ? "c1" : ""
            enabled: !Installer.scanning
            onClicked: Installer.scanWifi()
        }
        H.InkButton {
            visible: page.ssid !== ""
            text: Installer.connecting ? "connecting…" : "connect"
            ink: "c3"
            enabled: !Installer.connecting
            onClicked: Installer.connectWifi(page.ssid, wifiPassword.text)
        }
        H.InkButton {
            text: "look again"
            flat: true
            onClicked: Installer.refresh()
        }
    }

    Heading {
        text: "other ways in"
    }
    Line {
        ink: "subtle"
        text: "The text installer asks the same questions in the console. A shell is a root prompt on the live system; cake-install-gui brings this back."
    }
    Buttons {
        H.InkButton {
            text: "text installer"
            ink: "c1"
            onClicked: Installer.leave("tui")
        }
        H.InkButton {
            text: "open a shell"
            ink: "c1"
            onClicked: Installer.leave("shell")
        }
    }
}
