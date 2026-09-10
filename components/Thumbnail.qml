import QtQuick
import qs.Commons

Item {
    id: root
    objectName: "oshelf-thumbnail"
    property url source
    property bool failed: false
    property bool ready: false
    property bool rounded: false
    property real radius: 8
    property color borderColor: "transparent"
    property bool quiet: false
    implicitWidth: 64
    implicitHeight: 64
    onSourceChanged: reload.restart()
    onWidthChanged: reload.restart()
    onHeightChanged: reload.restart()
    onRadiusChanged: pic.requestPaint()
    onRoundedChanged: pic.requestPaint()
    Timer { id: reload; interval: 60; onTriggered: pic.load() }
    Canvas {
        id: pic
        anchors.fill: parent
        property url loadedSource
        function load() {
            if (!available) return;
            if (loadedSource.toString()) unloadImage(loadedSource);
            loadedSource = root.source;
            root.ready = false; root.failed = false;
            if (loadedSource.toString())
                loadImage(loadedSource, Qt.size(Math.max(1, Math.min(1024, width)), Math.max(1, Math.min(1024, height))));
            requestPaint();
        }
        onAvailableChanged: if (available) load()
        onImageLoaded: requestPaint()
        onPaint: {
            var c = getContext("2d");
            c.reset();
            if (!loadedSource.toString()) return;
            root.failed = isImageError(loadedSource);
            root.ready = isImageLoaded(loadedSource);
            if (!root.ready) return;
            // Canvas reports failures without QQuickImage logging the source URL.
            var pixels = c.createImageData(loadedSource.toString());
            if (!pixels || !pixels.width || !pixels.height) { root.ready = false; root.failed = true; return; }
            var ratio = Math.min(width / pixels.width, height / pixels.height);
            var w = pixels.width * ratio, h = pixels.height * ratio;
            if (root.rounded) {
                c.beginPath(); c.roundedRect(0, 0, width, height, root.radius, root.radius); c.clip();
            }
            c.drawImage(loadedSource, (width - w) / 2, (height - h) / 2, w, h);
        }
    }
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: root.borderColor === "transparent" ? 0 : 1
        border.color: root.borderColor
        visible: root.rounded && root.borderColor !== "transparent"
    }
    Text {
        anchors.centerIn: parent
        visible: root.failed && !root.quiet
        text: "Preview unavailable"
        color: Color.foreground
        opacity: 0.5
        font.family: Style.fontFamily
        font.pixelSize: 12
    }
}
