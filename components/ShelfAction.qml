import QtQuick
import qs.Commons

Rectangle {
    id: root
    required property string label
    signal triggered()
    implicitWidth: caption.implicitWidth + 24
    implicitHeight: 36
    radius: 8
    color: pointer.containsMouse || activeFocus ? Util.alpha(Color.foreground, 0.09) : "transparent"
    border.width: activeFocus ? 1 : 0
    border.color: Color.accent
    activeFocusOnTab: visible && enabled
    opacity: enabled ? 1 : 0.4
    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.onPressAction: triggered()
    Keys.onReturnPressed: triggered()
    Keys.onSpacePressed: triggered()
    Text {
        id: caption
        anchors.centerIn: parent
        text: root.label
        textFormat: Text.PlainText
        color: Color.foreground
        font.family: Style.fontFamily
        font.pixelSize: 12
    }
    MouseArea { id: pointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.triggered() }
}
