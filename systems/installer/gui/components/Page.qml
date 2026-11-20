import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common.widgets.haiiro as H

// One step's window: labelled like the command that would show it (`lsblk`,
// `passwd`), its lines in a scrolling column, key hints in the footer.
H.HWindow {
    id: root

    default property alias lines: column.data
    property alias flick: scroll

    hints: [
        {
            key: "pgup",
            text: "back"
        },
        {
            key: "pgdn",
            text: "next"
        },
        {
            key: "tab",
            text: "move"
        }
    ]

    Scroll {
        id: scroll
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
            id: column
            width: scroll.availableWidth - 16
            spacing: 0
        }
    }
}
