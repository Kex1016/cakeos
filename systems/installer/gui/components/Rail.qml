pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common.widgets.haiiro as H

// The steps, as the settings dashboard's `ls` rail: the current one an overlay
// band with a rose », finished ones ticked in foam, the ones you can't reach
// yet at 55%. Under them, what the installer found on this machine.
H.HWindow {
    id: root

    property var steps: []
    property int current: 0
    property int reachable: 0
    property bool installing: false
    signal picked(int index)

    label: "ls ~/install"

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 6
        spacing: 0

        Repeater {
            model: root.steps

            H.ListRow {
                id: row
                required property var modelData
                required property int index
                readonly property bool last: index === root.steps.length - 1
                readonly property bool open: root.installing ? last : index <= Math.min(root.reachable, root.steps.length - 2)
                readonly property bool done: root.installing ? !last || Installer.phase === "done" : index < root.current

                Layout.fillWidth: true
                text: modelData.id
                selected: root.current === index
                enabled: open
                opacity: open || done || selected ? 1 : 0.55
                meta: last && Installer.phase === "failed" ? "failed" : done ? "✓" : last && Installer.phase === "running" ? "running" : ""
                onClicked: if (open)
                    root.picked(index)
            }
        }
    }

    H.HRule {
        Layout.fillWidth: true
        Layout.topMargin: 6
    }

    H.HLabel {
        Layout.leftMargin: 8
        Layout.topMargin: 2
        Layout.bottomMargin: 4
        text: "this machine"
    }

    Repeater {
        model: [
            {
                k: "memory",
                v: Installer.probing ? "…" : Installer.ramGb + " GB"
            },
            {
                k: "network",
                v: Installer.probing ? "…" : Installer.online ? "online" : "offline"
            },
            {
                k: "disks",
                v: Installer.probing ? "…" : Installer.disks.length + " to choose from"
            }
        ]
        RowLayout {
            id: fact
            required property var modelData
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.topMargin: 2
            spacing: 12
            H.HText {
                text: fact.modelData.k
                role: "caption"
                ink: "subtle"
            }
            Item {
                Layout.fillWidth: true
            }
            H.HText {
                text: fact.modelData.v
                role: "caption"
                ink: fact.modelData.v === "offline" ? "love" : fact.modelData.v === "online" ? "foam" : "text"
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
