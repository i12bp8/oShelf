import QtQuick
import QtQuick.Controls
import qs.Commons

Rectangle {
    id: root
    required property string label
    property string icon: ""
    property string hint: label
    property bool selected: false
    signal triggered()
    implicitWidth: (label ? caption.implicitWidth : 0) + (icon ? 20 : 0) + (icon && label ? 7 : 0) + 22
    implicitHeight: 36
    radius: 10
    color: selected ? Util.alpha(Color.accent, 0.13) : pointer.containsMouse || activeFocus ? Util.alpha(Color.foreground, 0.075) : "transparent"
    border.width: 1
    border.color: activeFocus ? Color.accent : selected ? Util.alpha(Color.accent, 0.3) : "transparent"
    scale: pointer.pressed ? 0.96 : 1
    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: 120 } }
    activeFocusOnTab: true
    opacity: enabled ? 1 : 0.4
    Accessible.role: Accessible.Button
    Accessible.name: hint
    Accessible.onPressAction: triggered()
    Keys.onReturnPressed: triggered()
    Keys.onSpacePressed: triggered()
    ToolTip.visible: pointer.containsMouse && hint !== label
    ToolTip.text: hint
    ToolTip.delay: 650
    Row {
        anchors.centerIn: parent
        spacing: root.icon && root.label ? 7 : 0
        Glyph { visible: !!root.icon; kind: root.icon; width: root.icon ? 20 : 0; height: 20; ink: root.selected ? Color.accent : Color.foreground }
        Text {
        id: caption
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        textFormat: Text.PlainText
        color: root.selected ? Color.accent : Color.foreground
        font.family: Style.fontFamily
        font.pixelSize: 12
    }
    }
    MouseArea { id: pointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.triggered() }
}
