import QtQuick
import QtQuick.Layouts
import qs.modules.common.widgets.haiiro as H

// A question asked the way a shell would: `@ cakes » password:` and what you
// type after it, with the full block cursor. Passwords show as iris stars.
// `error` (love) or `hint` (subtle) goes on the line under it.
//   Field { user: "cakes"; label: "password"; password: true; text: ...; onEdited: t => ... }
ColumnLayout {
    id: root

    property string user: "root"
    property string label: ""
    property bool password: false
    property string error: ""
    property string hint: ""
    property alias text: input.text
    property alias input: input
    // The prompts of a group line up when they share this width.
    property int promptWidth: prompt.implicitWidth
    readonly property int naturalPromptWidth: prompt.implicitWidth
    signal edited(string text)
    signal accepted

    Layout.fillWidth: true
    spacing: 2

    function focusInput() {
        input.forceActiveFocus();
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: H.HTokens.lineBox(H.HTokens.fontBody) + 8

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.IBeamCursor
            onClicked: input.forceActiveFocus()
        }

        Rectangle {
            anchors.fill: parent
            visible: input.activeFocus
            color: H.HTokens.highlightLow
        }

        Row {
            id: prompt
            x: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: H.HTokens.ch()
            H.HText {
                text: "@"
                ink: "love"
            }
            H.HText {
                text: root.user
                ink: "foam"
            }
            H.HText {
                text: "»"
                ink: "rose"
            }
            H.HText {
                text: root.label + ":"
                ink: "gold"
            }
        }

        TextInput {
            id: input
            x: 8 + root.promptWidth + H.HTokens.ch()
            width: parent.width - x - 8
            anchors.verticalCenter: parent.verticalCenter
            height: H.HTokens.lineBox(H.HTokens.fontBody)
            verticalAlignment: TextInput.AlignVCenter
            color: root.password ? H.HTokens.iris : H.HTokens.text
            selectionColor: H.HTokens.pine
            selectedTextColor: H.HTokens.text
            renderType: Text.NativeRendering
            font.family: H.HTokens.mono
            font.pixelSize: H.HTokens.fontBody
            font.kerning: false
            font.hintingPreference: Font.PreferFullHinting
            font.letterSpacing: root.password ? 2 : 0
            echoMode: root.password ? TextInput.Password : TextInput.Normal
            passwordCharacter: "*"
            passwordMaskDelay: 0
            clip: true
            selectByMouse: true
            activeFocusOnTab: true
            onTextEdited: root.edited(text)
            onAccepted: root.accepted()
            cursorDelegate: Rectangle {
                width: H.HTokens.ch()
                height: H.HTokens.lineBox(H.HTokens.fontBody)
                color: H.HTokens.text
                visible: input.activeFocus
            }
        }
    }

    H.HText {
        Layout.fillWidth: true
        Layout.leftMargin: 8 + root.promptWidth + H.HTokens.ch()
        Layout.bottomMargin: 4
        visible: text !== ""
        text: root.error !== "" ? root.error : root.hint
        role: "caption"
        ink: root.error !== "" ? "love" : "subtle"
        wrapMode: Text.Wrap
    }
}
