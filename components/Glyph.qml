import QtQuick
import qs.Commons

Canvas {
    id: root
    property string kind: "file"
    property color ink: Color.foreground
    width: 22; height: 22
    onKindChanged: requestPaint()
    onInkChanged: requestPaint()
    onPaint: {
        var c = getContext("2d");
        c.reset(); c.strokeStyle = ink; c.lineWidth = 1.4; c.lineJoin = "round"; c.lineCap = "round";
        c.beginPath();
        if (kind === "folder") {
            c.moveTo(2, 6); c.lineTo(8, 6); c.lineTo(10, 8); c.lineTo(20, 8);
            c.lineTo(20, 18); c.lineTo(2, 18); c.closePath();
        } else if (kind === "url") {
            c.arc(11, 11, 8, 0, Math.PI * 2);
            c.moveTo(3, 11); c.lineTo(19, 11);
            c.moveTo(11, 3); c.bezierCurveTo(4, 8, 4, 14, 11, 19);
            c.moveTo(11, 3); c.bezierCurveTo(18, 8, 18, 14, 11, 19);
        } else {
            c.moveTo(5, 2); c.lineTo(13, 2); c.lineTo(18, 7); c.lineTo(18, 20); c.lineTo(5, 20); c.closePath();
            c.moveTo(13, 2); c.lineTo(13, 7); c.lineTo(18, 7);
            c.moveTo(8, 12); c.lineTo(15, 12); c.moveTo(8, 16); c.lineTo(13, 16);
        }
        c.stroke();
    }
}
