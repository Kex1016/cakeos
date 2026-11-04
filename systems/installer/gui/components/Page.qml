import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

// A scrolling page with the shell's settings-page title block.
ScrollView {
    id: root

    property string title
    property string subtitle: ""
    default property alias content: body.data

    contentWidth: availableWidth
    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    ColumnLayout {
        width: root.availableWidth
        spacing: 24

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            spacing: 6
            StyledText {
                Layout.fillWidth: true
                text: root.title
                font.pixelSize: Theme.font.title
                font.weight: Font.Medium
                color: Theme.colOnSurface
            }
            StyledText {
                Layout.fillWidth: true
                visible: root.subtitle !== ""
                text: root.subtitle
                color: Theme.subtext
                font.pixelSize: Theme.font.normal
            }
        }

        ColumnLayout {
            id: body
            Layout.fillWidth: true
            Layout.rightMargin: 12
            Layout.bottomMargin: 16
            spacing: 24
        }
    }
}
