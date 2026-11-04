import QtQuick
import QtQuick.Layouts
import qs
import qs.components

Page {
    id: page

    property string ssid: ""

    title: "Welcome to CakeOS"
    subtitle: "A NixOS flake, assembled. This installer erases a disk, sets CakeOS up on it and builds your system."

    Section {
        title: "Connection"
        icon: Installer.online ? "wifi" : "wifi_off"

        Notice {
            visible: !Installer.probing && Installer.online
            icon: "check_circle"
            text: "Connected to the internet."
        }
        Notice {
            visible: !Installer.probing && !Installer.online
            kind: "warning"
            text: Installer.hasWifi ? "No internet connection. Pick a Wi-Fi network below, or plug in a cable and press Check again." : "No internet connection and no Wi-Fi adapter. Plug in a cable and press Check again. Most of the system is downloaded during the install."
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 6
            visible: !Installer.online && Installer.hasWifi
            spacing: 4

            Repeater {
                model: Installer.networks
                ChoiceCard {
                    required property string modelData
                    icon: "wifi"
                    title: modelData
                    selected: page.ssid === modelData
                    onClicked: page.ssid = modelData
                }
            }

            TextField {
                Layout.topMargin: 10
                id: wifiPassword
                visible: page.ssid !== ""
                label: "Password for " + page.ssid
                password: true
                error: Installer.wifiError
            }
        }

        RowLayout {
            Layout.topMargin: 6
            spacing: 8
            Button {
                visible: !Installer.online && Installer.hasWifi
                kind: "tonal"
                icon: "wifi_find"
                text: Installer.scanning ? "Scanning..." : "Scan for networks"
                enabled: !Installer.scanning
                onClicked: Installer.scanWifi()
            }
            Button {
                visible: !Installer.online && page.ssid !== ""
                icon: "link"
                text: Installer.connecting ? "Connecting..." : "Connect"
                enabled: !Installer.connecting
                onClicked: Installer.connectWifi(page.ssid, wifiPassword.text)
            }
            Button {
                visible: !Installer.online
                kind: "text"
                icon: "refresh"
                text: "Check again"
                onClicked: Installer.refresh()
            }
        }
    }

    Section {
        title: "Other ways in"
        icon: "terminal"

        StyledText {
            Layout.fillWidth: true
            text: "The text installer asks the same questions in the console. A shell is a root prompt on the live system."
            color: Theme.subtext
        }
        RowLayout {
            Layout.topMargin: 6
            spacing: 8
            Button {
                kind: "tonal"
                icon: "keyboard"
                text: "Text installer"
                onClicked: Installer.leave("tui")
            }
            Button {
                kind: "text"
                icon: "terminal"
                text: "Open a shell"
                onClicked: Installer.leave("shell")
            }
        }
    }
}
