//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components
import qs.pages

// The graphical CakeOS installer: the hecate shell's settings window, over the
// CakeOS wallpaper, one page per step.
ShellRoot {
    FloatingWindow {
        id: window

        title: "CakeOS Installer"
        implicitWidth: 1280
        implicitHeight: 800
        color: Theme.background

        readonly property var steps: [
            { name: "Welcome", icon: "waving_hand", page: welcome, valid: true },
            { name: "Disk", icon: "hard_drive", page: disk, valid: Installer.disk !== "" },
            { name: "Desktop", icon: "desktop_windows", page: desktop, valid: Installer.desktop !== "" },
            { name: "Account", icon: "person", page: account, valid: Installer.accountValid },
            { name: "Region", icon: "language", page: region, valid: Installer.timeZone !== "" && Installer.layouts.length > 0 },
            { name: "Software", icon: "apps", page: software, valid: true },
            { name: "System", icon: "tune", page: system, valid: Installer.swapValid },
            { name: "Review", icon: "checklist", page: review, valid: true },
            { name: "Install", icon: "download", page: install, valid: false }
        ]
        readonly property int reachable: {
            const i = steps.findIndex(s => !s.valid);
            return i < 0 ? steps.length - 1 : i;
        }
        readonly property bool installing: Installer.phase !== "idle"
        property int current: 0

        function go(i) {
            if (!installing && i <= reachable)
                current = i;
        }

        Image {
            anchors.fill: parent
            source: Theme.wallpaper
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }

        Rectangle {
            id: shadow
            anchors.fill: card
            anchors.margins: -1
            anchors.topMargin: 2
            anchors.bottomMargin: -6
            radius: card.radius + 2
            color: Theme.alpha("#000000", 0.35)
        }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, 1080)
            height: Math.min(parent.height - 80, 720)
            radius: Theme.rounding.window
            color: Theme.layer0
            border.width: 1
            border.color: Theme.alpha(Theme.outlineVariant, 0.6)

            focus: true
            Keys.onPressed: event => {
                if (event.key === Qt.Key_PageDown) {
                    window.go(window.current + 1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_PageUp && window.current > 0) {
                    window.go(window.current - 1);
                    event.accepted = true;
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Rectangle {
                    Layout.fillHeight: true
                    implicitWidth: 236
                    radius: Theme.rounding.normal + 4
                    color: Theme.layer1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.topMargin: 22
                        anchors.leftMargin: 12
                        anchors.bottomMargin: 16
                        spacing: 4

                        RowLayout {
                            Layout.leftMargin: 8
                            Layout.bottomMargin: 14
                            spacing: 12
                            Rectangle {
                                implicitWidth: 48
                                implicitHeight: 48
                                radius: Theme.rounding.normal
                                color: Theme.primaryContainer
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "cake"
                                    fill: 1
                                    iconSize: 28
                                    color: Theme.colOnPrimaryContainer
                                }
                            }
                            ColumnLayout {
                                spacing: 0
                                StyledText {
                                    text: "CakeOS"
                                    font.pixelSize: Theme.font.larger
                                    font.weight: Font.Medium
                                    color: Theme.colOnLayer1
                                }
                                StyledText {
                                    text: "Installer"
                                    font.pixelSize: Theme.font.smaller
                                    color: Theme.subtext
                                }
                            }
                        }

                        Repeater {
                            model: window.steps
                            NavButton {
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                icon: modelData.icon
                                text: modelData.name
                                toggled: window.current === index
                                done: index < window.current && !window.installing || window.installing && index < window.steps.length - 1
                                enabled: window.installing ? index === window.steps.length - 1 : index <= Math.min(window.reachable, window.steps.length - 2)
                                onClicked: window.go(index)
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 20
                    Layout.leftMargin: 28
                    spacing: 16

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Repeater {
                            model: window.steps
                            Item {
                                required property var modelData
                                required property int index
                                readonly property bool active: window.current === index
                                anchors.fill: parent
                                anchors.topMargin: active ? 0 : 12
                                opacity: active ? 1 : 0
                                visible: opacity > 0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Theme.duration
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                Behavior on anchors.topMargin {
                                    NumberAnimation {
                                        duration: Theme.duration
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                Loader {
                                    anchors.fill: parent
                                    sourceComponent: parent.modelData.page
                                }
                            }
                        }
                    }

                    RowLayout {
                        readonly property bool reviewing: window.current === window.steps.length - 2
                        Layout.fillWidth: true
                        visible: !window.installing
                        spacing: 8
                        Button {
                            kind: "text"
                            icon: "arrow_back"
                            text: "Back"
                            visible: window.current > 0
                            onClicked: window.go(window.current - 1)
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        StyledText {
                            visible: !parent.reviewing
                            text: "Step " + (window.current + 1) + " of " + (window.steps.length - 1)
                            color: Theme.subtext
                            font.pixelSize: Theme.font.smaller + 1
                        }
                        Button {
                            visible: !parent.reviewing
                            icon: "arrow_forward"
                            text: "Next"
                            enabled: window.steps[window.current].valid
                            onClicked: window.go(window.current + 1)
                        }
                        Button {
                            visible: parent.reviewing
                            kind: "danger"
                            icon: "delete_forever"
                            text: "Erase and install"
                            onClicked: {
                                window.current = window.steps.length - 1;
                                Installer.install();
                            }
                        }
                    }
                }
            }
        }

        Component {
            id: welcome
            WelcomePage {}
        }
        Component {
            id: disk
            DiskPage {}
        }
        Component {
            id: desktop
            DesktopPage {}
        }
        Component {
            id: account
            AccountPage {}
        }
        Component {
            id: region
            RegionPage {}
        }
        Component {
            id: software
            SoftwarePage {}
        }
        Component {
            id: system
            SystemPage {}
        }
        Component {
            id: review
            ReviewPage {}
        }
        Component {
            id: install
            InstallPage {}
        }
    }
}
