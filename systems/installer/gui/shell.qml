//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1

pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components
import qs.pages
import qs.modules.common
import qs.modules.common.widgets.haiiro as H

// The graphical CakeOS installer in haiiro: the live blobs behind it, the step
// as a display title, the steps in a rail window and the current one in a
// window of its own, laid out like the shell's settings dashboard. The parts
// are hecate's haiiro kit (modules/common/widgets/haiiro, from the hecate input).
ShellRoot {
    FloatingWindow {
        id: window

        title: "CakeOS Installer"
        implicitWidth: 1280
        implicitHeight: 800
        color: H.HTokens.base

        readonly property var steps: [
            { id: "welcome", page: welcome, valid: true },
            { id: "disk", page: disk, valid: Installer.disk !== "" },
            { id: "desktop", page: desktop, valid: Installer.desktop !== "" },
            { id: "account", page: account, valid: Installer.accountValid },
            { id: "region", page: region, valid: Installer.timeZone !== "" && Installer.layouts.length > 0 },
            { id: "software", page: software, valid: true },
            { id: "system", page: system, valid: Installer.swapValid },
            { id: "review", page: review, valid: true },
            { id: "install", page: install, valid: false }
        ]
        readonly property int reachable: {
            const i = steps.findIndex(s => !s.valid);
            return i < 0 ? steps.length - 1 : i;
        }
        readonly property bool installing: Installer.phase !== "idle"
        readonly property bool reviewing: current === steps.length - 2
        property int current: 0

        // Smaller screens (a VM's 1024x768) get the smaller display title.
        readonly property bool compact: height < 860 || width < 1280
        readonly property int side: compact ? 32 : 50

        function go(i) {
            if (!installing && i >= 0 && i <= Math.min(reachable, steps.length - 2))
                current = i;
        }

        function start() {
            current = steps.length - 1;
            Installer.install();
        }

        Blobs {
            anchors.fill: parent
            still: Appearance.reducedMotion
            // nixos-install wants the CPU more than the background does, and
            // without GL every frame is drawn on the CPU too
            fps: Installer.phase === "running" ? (Appearance.software ? 4 : 8) : (Appearance.software ? 15 : 30)
        }
        H.Veil {
            anchors.fill: parent
            blocking: false
        }

        Item {
            id: frame
            anchors.fill: parent
            anchors.leftMargin: window.side
            anchors.rightMargin: window.side
            anchors.topMargin: window.compact ? 20 : 32
            anchors.bottomMargin: window.compact ? 20 : 24

            focus: true
            Keys.onPressed: event => {
                if (event.key === Qt.Key_PageDown) {
                    if (window.steps[window.current].valid && !window.reviewing)
                        window.go(window.current + 1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_PageUp) {
                    window.go(window.current - 1);
                    event.accepted = true;
                }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 18

                // the step as a display title, the prompt that would run it on the right
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 24

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: title.implicitHeight
                        H.HText {
                            x: 8
                            y: 8
                            text: title.text
                            role: "display"
                            ink: "base"
                            font.pixelSize: title.font.pixelSize
                            lineHeight: title.lineHeight
                        }
                        H.HText {
                            id: title
                            text: window.steps[window.current].id
                            role: "display"
                            font.pixelSize: window.compact ? 96 : 120
                            lineHeight: font.pixelSize
                        }
                    }
                    ColumnLayout {
                        Layout.alignment: Qt.AlignBottom
                        Layout.bottomMargin: 10
                        spacing: 4
                        H.PromptLine {
                            Layout.alignment: Qt.AlignRight
                            path: "~/install"
                            command: "cake-install"
                            args: window.steps[window.current].id
                        }
                        H.HText {
                            Layout.alignment: Qt.AlignRight
                            text: "CakeOS · live system"
                            role: "caption"
                            ink: "inkMuted"
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 24

                    Rail {
                        Layout.fillHeight: true
                        Layout.preferredWidth: window.compact ? 240 : 280
                        steps: window.steps
                        current: window.current
                        reachable: window.reachable
                        installing: window.installing
                        onPicked: i => window.go(i)
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Repeater {
                            model: window.steps

                            // A new step pixelates in; the old one cuts away.
                            Item {
                                id: slot
                                required property var modelData
                                required property int index
                                readonly property bool active: window.current === index
                                anchors.fill: parent
                                visible: active

                                H.PixelTransition {
                                    anchors.fill: parent
                                    shown: slot.active
                                    animateOnLoad: false

                                    Loader {
                                        width: slot.width
                                        height: slot.height
                                        sourceComponent: slot.modelData.page
                                    }
                                }
                            }
                        }
                    }
                }

                // back, where you are, next
                RowLayout {
                    Layout.fillWidth: true
                    visible: !window.installing
                    spacing: 16

                    H.InkButton {
                        visible: window.current > 0
                        text: "back"
                        ink: "c1"
                        onClicked: window.go(window.current - 1)
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    H.HText {
                        visible: !window.reviewing
                        text: "step " + (window.current + 1) + " of " + (window.steps.length - 1)
                        role: "caption"
                        ink: "inkMuted"
                    }
                    H.InkButton {
                        visible: !window.reviewing
                        text: "next"
                        ink: "c3"
                        enabled: window.steps[window.current].valid
                        onClicked: window.go(window.current + 1)
                    }
                    H.HText {
                        visible: window.reviewing
                        text: "this erases " + Installer.disk
                        role: "caption"
                        ink: "love"
                    }
                    H.InkButton {
                        visible: window.reviewing
                        text: "erase and install"
                        ink: "c2"
                        onClicked: window.start()
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
