import QtQuick
import QtQuick.Layouts
import qs
import qs.components

Page {
    id: page

    readonly property var rows: [
        { icon: "hard_drive", label: "Disk", value: Installer.disk },
        { icon: "desktop_windows", label: "Desktop", value: Installer.desktop },
        { icon: "computer", label: "Hostname", value: Installer.hostname },
        { icon: "person", label: "User", value: Installer.username + (Installer.autoLogin ? " (logs in automatically)" : "") },
        { icon: "storage", label: "Data disk", value: Installer.mainframe ? Installer.mainframeDevice + (Installer.mainframeSsh ? " (+ ~/.ssh)" : "") : "None" },
        { icon: "schedule", label: "Time zone", value: Installer.timeZone },
        { icon: "keyboard", label: "Keyboard", value: Installer.keyboardLayouts().join(", ") },
        { icon: "apps", label: "Groups", value: Installer.groups.join(", ") || "None" },
        { icon: "devices_other", label: "Hardware", value: Installer.hardware.join(", ") || "None" },
        { icon: "memory", label: "Kernel", value: Installer.kernel },
        { icon: "swap_horiz", label: "Swap", value: Installer.swapSize },
        { icon: "speed", label: "tmpfs", value: Installer.ramGb > 16 ? ["/tmp", "/etc"].filter((_, i) => [Installer.tmpfsTmp, Installer.tmpfsEtc][i]).join(", ") || "None" : "None" }
    ]

    title: "Review"
    subtitle: "Check everything before the disk is erased. You can still go back and change any of it."

    Notice {
        kind: "error"
        text: "Installing erases everything on " + Installer.disk + "."
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: summary.implicitHeight + 16
        radius: Theme.rounding.normal
        color: Theme.layer2

        ColumnLayout {
            id: summary
            anchors.fill: parent
            anchors.margins: 8
            spacing: 0

            Repeater {
                model: page.rows
                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    Layout.leftMargin: 12
                    Layout.rightMargin: 12
                    spacing: 14
                    MaterialSymbol {
                        text: parent.modelData.icon
                        color: Theme.colOnSurfaceVariant
                    }
                    StyledText {
                        Layout.preferredWidth: 120
                        text: parent.modelData.label
                        color: Theme.subtext
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: parent.modelData.value
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                        font.weight: Font.Medium
                    }
                }
            }
        }
    }
}
