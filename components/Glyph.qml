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
        c.scale(width / 22, height / 22);
        c.beginPath();
        if (kind === "shelf") {
            c.moveTo(3, 12); c.lineTo(3, 19); c.lineTo(19, 19); c.lineTo(19, 12);
            c.moveTo(6, 9); c.lineTo(6, 3); c.lineTo(16, 3); c.lineTo(16, 9);
            c.moveTo(11, 7); c.lineTo(11, 14); c.moveTo(8, 11); c.lineTo(11, 14); c.lineTo(14, 11);
        } else if (kind === "close") {
            c.moveTo(6, 6); c.lineTo(16, 16); c.moveTo(16, 6); c.lineTo(6, 16);
        } else if (kind === "search") {
            c.arc(9, 9, 5, 0, Math.PI * 2); c.moveTo(13, 13); c.lineTo(19, 19);
        } else if (kind === "settings") {
            for (var i = 0; i < 3; i++) {
                var y = 5 + i * 6, x = i === 1 ? 14 : 8;
                c.moveTo(3, y); c.lineTo(x - 2, y); c.moveTo(x + 2, y); c.lineTo(19, y);
                c.moveTo(x + 2, y); c.arc(x, y, 2, 0, Math.PI * 2);
            }
        } else if (kind === "compact") {
            for (var row = 0; row < 3; row++) { c.rect(3, 3 + row * 6, 3, 3); c.moveTo(10, 4.5 + row * 6); c.lineTo(19, 4.5 + row * 6); }
        } else if (kind === "pin") {
            c.moveTo(7, 3); c.lineTo(15, 3); c.lineTo(14, 10); c.lineTo(17, 14); c.lineTo(5, 14); c.lineTo(8, 10); c.closePath();
            c.moveTo(11, 14); c.lineTo(11, 20);
        } else if (kind === "image") {
            c.rect(3, 3, 16, 16); c.moveTo(3, 16); c.lineTo(8, 11); c.lineTo(12, 15); c.lineTo(15, 12); c.lineTo(19, 16);
            c.moveTo(15, 7); c.arc(13, 7, 2, 0, Math.PI * 2);
        } else if (kind === "text") {
            c.moveTo(4, 5); c.lineTo(18, 5); c.moveTo(4, 9); c.lineTo(15, 9);
            c.moveTo(4, 13); c.lineTo(18, 13); c.moveTo(4, 17); c.lineTo(11, 17);
        } else if (kind === "folder") {
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
