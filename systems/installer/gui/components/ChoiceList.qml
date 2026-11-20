pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common.widgets.haiiro as H

// One choice out of a few (disks, desktops, networks): rows in the ListRow
// style, the chosen one an overlay band with a rose » in front, a subtle
// second line under the name and a muted value on the right.
//   ChoiceList { model: [{ key, title, description, meta }]; current: "..."; onChosen: key => ... }
// Up and Down move the choice when the list has focus.
Item {
    id: root

    property var model: []
    property string current: ""
    signal chosen(string key)

    Layout.fillWidth: true
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight
    activeFocusOnTab: model.length > 0

    function move(by) {
        const i = model.findIndex(m => m.key === current);
        const next = Math.max(0, Math.min(model.length - 1, i < 0 ? 0 : i + by));
        if (model.length > 0)
            chosen(model[next].key);
    }

    Keys.onUpPressed: move(-1)
    Keys.onDownPressed: move(1)

    ColumnLayout {
        id: col
        width: root.width
        spacing: 0

        Repeater {
            model: root.model

            Item {
                id: row
                required property var modelData
                readonly property bool selected: modelData.key === root.current

                Layout.fillWidth: true
                implicitHeight: lines.implicitHeight + 12

                Rectangle {
                    anchors.fill: parent
                    visible: row.selected
                    color: H.HTokens.overlay
                }
                Rectangle {
                    anchors.fill: parent
                    visible: !row.selected && mouse.containsMouse
                    color: H.HTokens.highlightLow
                }

                RowLayout {
                    id: lines
                    x: 8
                    width: parent.width - 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    H.HText {
                        Layout.alignment: Qt.AlignTop
                        Layout.preferredWidth: H.HTokens.ch()
                        text: "»"
                        ink: "rose"
                        opacity: row.selected ? 1 : 0
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        H.HText {
                            Layout.fillWidth: true
                            text: row.modelData.title
                            ink: "text"
                            elide: Text.ElideRight
                        }
                        H.HText {
                            Layout.fillWidth: true
                            visible: (row.modelData.description ?? "") !== ""
                            text: row.modelData.description ?? ""
                            role: "caption"
                            ink: "subtle"
                            wrapMode: Text.Wrap
                        }
                    }
                    H.HText {
                        Layout.alignment: Qt.AlignTop
                        visible: (row.modelData.meta ?? "") !== ""
                        text: row.modelData.meta ?? ""
                        ink: row.selected ? "foam" : "subtle"
                    }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.forceActiveFocus();
                        root.chosen(row.modelData.key);
                    }
                }
            }
        }
    }

    // focus: the foam outline the kit gives every control
    Rectangle {
        visible: root.activeFocus
        anchors.fill: parent
        anchors.margins: -4
        color: "transparent"
        border.width: 2
        border.color: H.HTokens.foam
    }
}
