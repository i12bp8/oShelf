pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.Commons

Item {
    id: root
    required property var preferences
    property var draft: preferences.defaults()
    signal applied()
    signal cancelled()
    function begin() { draft = Object.assign({}, preferences.values); }
    function change(key, value) { var next = Object.assign({}, draft); next[key] = value; draft = next; }
    Flickable {
        id: scroll
        anchors { top: parent.top; left: parent.left; right: parent.right; bottom: footer.top; bottomMargin: 14 }
        clip: true; contentHeight: controls.height
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        Column {
            id: controls; width: scroll.width - 12; spacing: 18
            Text { text: "AT HOME ON YOUR SCREEN"; color: Color.accent; font.family: Style.fontFamily; font.pixelSize: 10; font.letterSpacing: 1.1 }
            Row {
                spacing: 8
                Repeater {
                    model: ["left", "bottom", "right"]
                    ShelfAction {
                        required property string modelData
                        label: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                        selected: root.draft.placement === modelData
                        onTriggered: root.change("placement", modelData)
                    }
                }
            }
            Rectangle {
                width: parent.width; height: 88; radius: 12
                color: Util.alpha(Color.foreground, 0.025)
                border.width: 1; border.color: Util.alpha(Color.foreground, 0.1)
                Rectangle {
                    readonly property bool horizontal: root.draft.placement === "bottom"
                    width: horizontal ? Math.max(24, parent.width * root.draft.activationLength / 1500) : 4
                    height: horizontal ? 4 : Math.max(16, parent.height * root.draft.activationLength / 850)
                    x: horizontal ? (parent.width - width) * root.draft.activationPosition / 100 : root.draft.placement === "left" ? 5 : parent.width - width - 5
                    y: horizontal ? parent.height - height - 5 : (parent.height - height) * root.draft.activationPosition / 100
                    radius: 2; color: Color.accent
                    Behavior on x { NumberAnimation { duration: 150 } }
                    Behavior on y { NumberAnimation { duration: 150 } }
                }
                Text { anchors.centerIn: parent; text: "Activation zone preview"; color: Util.alpha(Color.foreground, 0.4); font.family: Style.fontFamily; font.pixelSize: 10 }
            }
            Repeater {
                model: root.draft.placement === "bottom" ? [
                    {key: "bottomWidth", label: "Tray width", minimum: 560, maximum: 1400},
                    {key: "bottomHeight", label: "Tray height", minimum: 400, maximum: 800}
                ] : [
                    {key: "sideWidth", label: "Panel width", minimum: 360, maximum: 640},
                    {key: "sideHeight", label: "Panel height", minimum: 460, maximum: 1000}
                ]
                PreferenceSlider {
                    required property var modelData
                    width: controls.width; label: modelData.label
                    description: "Automatically fits smaller displays"
                    minimum: modelData.minimum; maximum: modelData.maximum; step: 20; suffix: " px"
                    value: root.draft[modelData.key]
                    onEdited: next => root.change(modelData.key, next)
                }
            }
            Repeater {
                model: [
                    {key: "activationPosition", label: "Position along edge", description: "Top → bottom on sides · left → right at the bottom", minimum: 10, maximum: 90, step: 5, suffix: "%"},
                    {key: "activationLength", label: "Activation length", description: "Only this part of the edge opens the shelf", minimum: 80, maximum: 600, step: 20, suffix: " px"},
                    {key: "activationDepth", label: "Activation depth", description: "How far the target reaches into your desktop", minimum: 4, maximum: 24, step: 2, suffix: " px"},
                    {key: "openDelay", label: "Hover to open", description: "A short pause avoids accidental openings", minimum: 150, maximum: 1500, step: 50, suffix: " ms"},
                    {key: "closeDelay", label: "Leave to close", description: "Time to return before the shelf slides away", minimum: 250, maximum: 2500, step: 50, suffix: " ms"},
                    {key: "motionDuration", label: "Animation duration", description: "Quick and crisp → soft and unhurried", minimum: 120, maximum: 420, step: 20, suffix: " ms"}
                ]
                PreferenceSlider {
                    required property var modelData
                    width: controls.width
                    label: modelData.label; description: modelData.description
                    minimum: modelData.minimum; maximum: modelData.maximum; step: modelData.step; suffix: modelData.suffix
                    value: root.draft[modelData.key]
                    enabled: modelData.key !== "motionDuration" || !root.draft.reducedMotion
                    opacity: enabled ? 1 : 0.4
                    onEdited: next => root.change(modelData.key, next)
                }
            }
            ShelfAction {
                label: "Require a steady hover"; icon: "pin"
                selected: root.draft.steadyHover
                onTriggered: root.change("steadyHover", !root.draft.steadyHover)
            }
            Text {
                width: parent.width; wrapMode: Text.Wrap
                text: "Moving more than 6 px restarts the hover timer. Dragging an item to the edge opens immediately."
                color: Util.alpha(Color.foreground, 0.55); font.family: Style.fontFamily; font.pixelSize: 10
            }
            ShelfAction {
                label: "Reduced motion"; selected: root.draft.reducedMotion
                onTriggered: root.change("reducedMotion", !root.draft.reducedMotion)
            }
            Text {
                visible: !!root.preferences.error
                width: parent.width; text: root.preferences.error; wrapMode: Text.Wrap
                color: Color.urgent; font.family: Style.fontFamily; font.pixelSize: 11
            }
        }
    }
    Row {
        id: footer
        anchors { bottom: parent.bottom; right: parent.right }
        spacing: 4
        ShelfAction { label: "Defaults"; onTriggered: root.draft = root.preferences.defaults() }
        ShelfAction { label: "Cancel"; onTriggered: root.cancelled() }
        ShelfAction { label: "Apply"; selected: true; enabled: root.preferences.ready; onTriggered: { if (root.preferences.apply(root.draft)) root.applied(); } }
    }
}
