import QtQuick
import qs

Text {
    property real iconSize: 22
    property real fill: 0

    color: Theme.colOnSurface
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    font.family: Theme.font.icon
    font.pixelSize: iconSize
    font.weight: fill > 0.5 ? Font.DemiBold : Font.Normal
    font.variableAxes: ({
            "FILL": fill > 0.5 ? 1 : 0,
            "opsz": iconSize
        })
}
