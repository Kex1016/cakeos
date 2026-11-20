pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.modules.common.widgets.haiiro as H

Page {
    id: page

    readonly property bool running: Installer.phase === "running"
    readonly property bool done: Installer.phase === "done"
    readonly property bool failed: Installer.phase === "failed"
    readonly property int finished: done ? Installer.stages.length : Installer.stagesDone.length
    property bool showLog: failed

    label: done ? "nixos-install: done" : failed ? "nixos-install: failed" : "nixos-install"
    variant: done ? "foam" : failed ? "love" : "pine"
    hints: []
    note: failed && Installer.crashReport !== "" ? Installer.crashReport : "/var/log/cake-installer.log"

    Line {
        ink: page.failed ? "love" : "rose"
        text: page.done ? "It's built. Take the installer out and restart into your new system." : page.failed ? (Installer.error || "Something went wrong.") : "The machine is building itself. Most of CakeOS is downloaded or compiled now, so this takes a while."
    }

    Heading {
        text: "stages"
    }
    Repeater {
        model: Installer.stages

        RowLayout {
            id: stage
            required property var modelData
            readonly property bool finished: Installer.stagesDone.includes(modelData.id) || page.done
            readonly property bool current: Installer.stage === modelData.id && !page.done

            Layout.fillWidth: true
            Layout.preferredHeight: 28
            spacing: 12

            H.HText {
                Layout.leftMargin: 8
                Layout.preferredWidth: 2 * H.HTokens.ch()
                text: stage.finished ? "✓" : stage.current ? (page.failed ? "×" : spinner.frame) : "·"
                ink: stage.finished ? "foam" : stage.current ? (page.failed ? "love" : "rose") : "muted"
            }
            H.HText {
                Layout.fillWidth: true
                text: stage.modelData.name
                ink: stage.finished || stage.current ? "text" : "muted"
            }
            H.HText {
                visible: stage.current
                text: page.failed ? "stopped here" : "now"
                role: "caption"
                ink: page.failed ? "love" : "inkMuted"
            }
        }
    }

    // A spinner made of steps, like everything else that moves.
    Timer {
        id: spinner
        property int n: 0
        readonly property string frame: "|/-\\"[n % 4]
        interval: 125
        repeat: true
        running: page.running && page.visible && !H.HTokens.cut
        onTriggered: n++
    }

    H.Progress {
        Layout.fillWidth: true
        Layout.topMargin: 12
        label: page.done ? "installed" : page.failed ? "stopped" : "installing"
        count: page.finished + " / " + Installer.stages.length
        value: page.finished / Installer.stages.length
    }
    H.HText {
        Layout.fillWidth: true
        Layout.topMargin: 6
        visible: page.running && Installer.status !== ""
        text: Installer.status
        role: "code"
        ink: "inkMuted"
        elide: Text.ElideRight
    }
    Line {
        Layout.topMargin: 6
        visible: page.failed && Installer.crashReport !== ""
        role: "caption"
        ink: "love"
        text: "A crash report is at " + Installer.crashReport + (Installer.crashReport.startsWith("/mnt/") ? "." : ". It lives in RAM and is gone after a restart, so copy it off first.")
    }

    Buttons {
        visible: !page.running
        H.InkButton {
            visible: page.done
            text: "restart now"
            ink: "c3"
            onClicked: Installer.reboot()
        }
        H.InkButton {
            visible: page.failed
            text: "open a shell"
            ink: "c3"
            onClicked: Installer.leave("shell")
        }
        H.InkButton {
            visible: page.failed
            text: "restart"
            ink: "c1"
            onClicked: Installer.reboot()
        }
    }

    Heading {
        text: "output"
    }
    H.InkButton {
        text: page.showLog ? "hide the output" : "show the output"
        flat: true
        on: page.showLog
        onClicked: page.showLog = !page.showLog
    }
    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 6
        visible: page.showLog
        implicitHeight: 260
        color: H.HTokens.base

        ListView {
            id: log
            anchors.fill: parent
            anchors.margins: 8
            clip: true
            model: Installer.log
            boundsBehavior: Flickable.StopAtBounds
            onCountChanged: positionViewAtEnd()
            delegate: H.HText {
                required property string modelData
                width: log.width
                text: modelData
                role: "small"
                ink: /error|fail/i.test(modelData) ? "love" : "subtle"
                wrapMode: Text.WrapAnywhere
                lineHeightMode: Text.FixedHeight
            }
        }
    }
}
