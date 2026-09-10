import QtQuick
import QtQuick.Controls
import qs.Commons

Column {
    id: root
    required property string label
    required property string description
    required property real value
    required property real minimum
    required property real maximum
    property real step: 1
    property string suffix: ""
    signal edited(real next)
    spacing: 4
    Row {
        width: parent.width
        Text { width: parent.width - amount.width; text: root.label; color: Color.foreground; font.family: Style.fontFamily; font.pixelSize: 12 }
        Text { id: amount; text: Math.round(root.value) + root.suffix; color: Color.accent; font.family: Style.fontFamily; font.pixelSize: 11 }
    }
    Text { width: parent.width; text: root.description; color: Util.alpha(Color.foreground, 0.55); font.family: Style.fontFamily; font.pixelSize: 10; wrapMode: Text.Wrap }
    Slider {
        id: slider
        width: parent.width; height: 28
        from: root.minimum; to: root.maximum; stepSize: root.step; value: root.value
        Accessible.name: root.label
        onMoved: root.edited(value)
        background: Rectangle {
            x: slider.leftPadding; y: (slider.height - height) / 2
            width: slider.availableWidth; height: 3; radius: 2
            color: Util.alpha(Color.foreground, 0.12)
            Rectangle { width: slider.visualPosition * parent.width; height: parent.height; radius: 2; color: Color.accent }
        }
        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: (slider.height - height) / 2; width: 14; height: 14; radius: 7
            color: Color.accent
            border.width: slider.activeFocus ? 2 : 0; border.color: Color.foreground
            scale: slider.pressed ? 1.18 : 1
            Behavior on scale { NumberAnimation { duration: 100 } }
        }
    }
}
