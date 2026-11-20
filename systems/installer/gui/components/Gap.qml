import QtQuick
import QtQuick.Layouts

// An empty line (the site's empty <p>), or any fixed gap.
Item {
    property int size: 16
    Layout.fillWidth: true
    implicitHeight: size
}
