import QtQuick
import QtQuick.Layouts

// Two Halves side by side when the window is wide enough, one above the other
// when not, like the settings dashboard's pages.
GridLayout {
    Layout.fillWidth: true
    columns: width > 820 ? 2 : 1
    columnSpacing: 40
    rowSpacing: 0
}
