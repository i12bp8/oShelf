import QtQuick
import qs.Commons

Canvas {
    id: root
    property url source
    property url loadedSource
    property bool ready: false
    property bool failed: false
    function reload() {
        if (!available) return;
        if (loadedSource.toString()) unloadImage(loadedSource);
        loadedSource = source;
        ready = false; failed = false;
        if (source.toString()) loadImage(source, Qt.size(620, 284));
        requestPaint();
    }
    onAvailableChanged: if (available) reload()
    onSourceChanged: reload()
    onImageLoaded: {
        ready = isImageLoaded(source);
        failed = isImageError(source);
        requestPaint();
    }
    onPaint: {
        var context = getContext("2d");
        context.reset();
        if (!ready || !isImageLoaded(source)) return;
        var pixels = context.createImageData(source.toString());
        if (!pixels || !pixels.width || !pixels.height) {
            failed = true;
            return;
        }
        var ratio = Math.min(width / pixels.width, height / pixels.height);
        var w = pixels.width * ratio, h = pixels.height * ratio;
        context.drawImage(source.toString(), (width - w) / 2, (height - h) / 2, w, h);
    }
    Text {
        anchors.centerIn: parent
        visible: root.failed
        text: "Preview unavailable"
        color: Color.foreground; opacity: 0.5
        font.family: Style.fontFamily; font.pixelSize: 12
    }
}
