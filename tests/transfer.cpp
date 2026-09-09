#include <QApplication>
#include <QDrag>
#include <QDragEnterEvent>
#include <QDropEvent>
#include <QLabel>
#include <QMimeData>
#include <QMouseEvent>
#include <QPainter>
#include <QBuffer>
#include <QImage>
#include <QUrl>
#include <cstdio>

class Transfer final : public QWidget {
public:
    Transfer() { setAcceptDrops(true); resize(600, 400); setWindowTitle("oShelf transfer test"); }
protected:
    void paintEvent(QPaintEvent *) override {
        QPainter p(this); p.fillRect(rect(), QColor("#151515")); p.setPen(Qt::white);
        p.setFont(QFont("sans-serif", 22));
        p.drawText(rect(), Qt::AlignCenter, "Drag from here to oShelf\nDrop a shelf card back here");
    }
    void mousePressEvent(QMouseEvent *e) override { start = e->position().toPoint(); started = false; std::puts("PRESS"); std::fflush(stdout); }
    void mouseMoveEvent(QMouseEvent *e) override {
        if (started || !(e->buttons() & Qt::LeftButton) || (e->position().toPoint() - start).manhattanLength() < 10) return;
        started = true;
        auto *mime = new QMimeData;
        mime->setText("Park anything. Pick it up anywhere.");
        mime->setData("application/x-oshelf-test", QByteArray::fromHex("00ff800a"));
        const auto args = QApplication::arguments();
        if (args.size() > 1 && args[1] == "--bad-image") {
            mime->setData("image/png", "OSHELF_PRIVATE_BAD_IMAGE");
        } else if (args.size() > 1 && args[1] == "--image") {
            QImage image(640, 400, QImage::Format_RGB32); image.fill(QColor("#b9c5ae"));
            QPainter painter(&image); painter.setPen(QColor("#233124")); painter.setFont(QFont("sans-serif", 40));
            painter.drawText(image.rect(), Qt::AlignCenter, "A little breathing room."); painter.end();
            QByteArray png; QBuffer buffer(&png); buffer.open(QIODevice::WriteOnly); image.save(&buffer, "PNG");
            mime->setData("image/png", png);
        } else if (args.size() > 1 && args[1] == "--url") {
            mime->setUrls({QUrl("https://omarchy.org/")});
        } else if (args.size() > 1) {
            QList<QUrl> urls; for (int i = 1; i < args.size(); ++i) urls.append(QUrl::fromLocalFile(args[i]));
            mime->setUrls(urls);
        }
        expected.clear();
        for (const auto &format : mime->formats()) expected.insert(format, mime->data(format));
        QDrag drag(this); drag.setMimeData(mime);
        const auto action = drag.exec(Qt::CopyAction);
        std::printf("SOURCE %d\n", int(action)); std::fflush(stdout);
    }
    void dragEnterEvent(QDragEnterEvent *e) override { e->acceptProposedAction(); }
    void dropEvent(QDropEvent *e) override {
        const auto *mime = e->mimeData();
        const bool exact = mime->data("application/x-oshelf-test") == QByteArray::fromHex("00ff800a");
        bool all = true;
        for (auto it = expected.cbegin(); it != expected.cend(); ++it) all = all && mime->data(it.key()) == it.value();
        std::printf("EXACT %d\n", all);
        std::printf("RECEIVED text=%d binary=%d urls=%d\n", mime->text() == "Park anything. Pick it up anywhere.", exact, int(mime->urls().size()));
        std::fflush(stdout); e->acceptProposedAction();
    }
private:
    QMap<QString, QByteArray> expected;
    QPoint start;
    bool started = false;
};
int main(int argc, char **argv) { QApplication app(argc, argv); app.setDesktopFileName("oshelf-test"); Transfer window; window.show(); return app.exec(); }
