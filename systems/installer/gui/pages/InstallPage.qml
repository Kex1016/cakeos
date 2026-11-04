import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs
import qs.components

Page {
    id: page

    property bool showLog: Installer.phase === "failed"

    title: Installer.phase === "done" ? "CakeOS is installed" : Installer.phase === "failed" ? "The install failed" : "Installing CakeOS"
    subtitle: Installer.phase === "done" ? "Remove the installation media, then restart into your new system." : Installer.phase === "failed" ? Installer.error : "This takes a while: most of the system is downloaded or built now."

    Section {
        title: "Progress"
        icon: Installer.phase === "done" ? "task_alt" : Installer.phase === "failed" ? "error" : "downloading"

        Repeater {
            model: Installer.stages
            RowLayout {
                id: stageRow
                required property var modelData
                readonly property bool done: Installer.stagesDone.includes(modelData.id) || Installer.phase === "done"
                readonly property bool current: Installer.stage === modelData.id && Installer.phase !== "done"
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                spacing: 14

                Item {
                    implicitWidth: 28
                    implicitHeight: 28
                    MaterialSymbol {
                        anchors.centerIn: parent
                        visible: !spinner.visible
                        text: stageRow.done ? "check_circle" : stageRow.current && Installer.phase === "failed" ? "cancel" : "radio_button_unchecked"
                        fill: stageRow.done || stageRow.current ? 1 : 0
                        color: stageRow.done ? Theme.primary : stageRow.current ? Theme.error : Theme.outline
                    }
                    MaterialSymbol {
                        id: spinner
                        anchors.centerIn: parent
                        visible: stageRow.current && Installer.phase === "running"
                        text: "progress_activity"
                        color: Theme.primary
                        RotationAnimation on rotation {
                            running: spinner.visible
                            from: 0
                            to: 360
                            duration: 1000
                            loops: Animation.Infinite
                        }
                    }
                }
                StyledText {
                    Layout.fillWidth: true
                    text: stageRow.modelData.name
                    color: stageRow.done || stageRow.current ? Theme.colOnSurface : Theme.subtext
                    font.weight: stageRow.current ? Font.Medium : Font.Normal
                }
            }
        }

        // Indeterminate bar, like the shell's StyledIndeterminateProgressBar.
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 8
            visible: Installer.phase === "running"
            implicitHeight: 6
            radius: 3
            color: Theme.secondaryContainer
            clip: true
            Rectangle {
                id: runner
                width: parent.width * 0.3
                height: parent.height
                radius: 3
                color: Theme.primary
                NumberAnimation on x {
                    from: -runner.width
                    to: runner.parent.width
                    duration: 1600
                    loops: Animation.Infinite
                    running: Installer.phase === "running"
                    easing.type: Easing.InOutCubic
                }
            }
        }
        StyledText {
            Layout.fillWidth: true
            visible: Installer.phase === "running"
            text: Installer.status
            color: Theme.subtext
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            font.family: Theme.font.mono
            font.pixelSize: Theme.font.smaller
        }
    }

    Notice {
        visible: Installer.phase === "failed" && Installer.crashReport !== ""
        kind: "error"
        text: "A crash report was written to " + Installer.crashReport + (Installer.crashReport.startsWith("/mnt/") ? "." : ". It lives in RAM and is lost on reboot, so copy it off first.")
    }

    RowLayout {
        Layout.fillWidth: true
        visible: Installer.phase !== "running"
        spacing: 8
        Item {
            Layout.fillWidth: true
        }
        Button {
            visible: Installer.phase === "failed"
            kind: "text"
            icon: "terminal"
            text: "Open a shell"
            onClicked: Installer.leave("shell")
        }
        Button {
            icon: "restart_alt"
            text: "Restart"
            onClicked: Installer.reboot()
        }
    }

    Section {
        title: "Output"
        icon: "article"

        Button {
            kind: "text"
            icon: page.showLog ? "expand_less" : "expand_more"
            text: page.showLog ? "Hide the output" : "Show the output"
            onClicked: page.showLog = !page.showLog
        }
        Rectangle {
            Layout.fillWidth: true
            visible: page.showLog
            implicitHeight: 300
            radius: Theme.rounding.small
            color: Theme.surfaceContainerLow

            ListView {
                id: logView
                anchors.fill: parent
                anchors.margins: 12
                clip: true
                model: Installer.log
                onCountChanged: positionViewAtEnd()
                ScrollBar.vertical: ScrollBar {}
                delegate: StyledText {
                    required property string modelData
                    width: logView.width
                    text: modelData
                    wrapMode: Text.WrapAnywhere
                    font.family: Theme.font.mono
                    font.pixelSize: Theme.font.smaller
                    color: Theme.colOnSurfaceVariant
                }
            }
        }
    }
}
