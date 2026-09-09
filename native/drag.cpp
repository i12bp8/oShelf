#include <QDrag>
#include <QEvent>
#include <QGuiApplication>
#include <QMimeData>
#include <QPointer>
#include <QPixmap>
#include <QQmlExtensionPlugin>
#include <QQuickItem>
#include <QQuickItemGrabResult>
#include <QTimer>
#include <qqml.h>

// Wayland's drop/finish events are authoritative. A queued Qt mouse release
// must not end QBasicDrag before the compositor has delivered the drop.
class DragReleaseFilter final : public QObject {
public:
    bool eventFilter(QObject *, QEvent *event) override {
        return event->type() == QEvent::MouseButtonRelease;
    }
};

class NativeDrag : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool active READ active NOTIFY activeChanged)
public:
    using QObject::QObject;
    ~NativeDrag() override {
        if (m_drag) QDrag::cancel();
    }
    bool active() const { return m_active; }

    Q_INVOKABLE void start(QQuickItem *item, const QVariantMap &formats) {
        if (m_active || !item || !item->window() || formats.isEmpty()) return;
        m_active = true;
        emit activeChanged();
        const QPointer<NativeDrag> owner(this);
        m_grab = item->grabToImage(QSize(260, 170));
        if (!m_grab) { finish(Qt::IgnoreAction); return; }
        QObject::connect(m_grab.data(), &QQuickItemGrabResult::ready, this,
                         [owner, formats] {
            if (!owner) return;
            const auto grab = owner->m_grab;
            const QPixmap preview = QPixmap::fromImage(grab->image());
            owner->m_grab.reset();
            // No QML evaluation may remain on the stack inside QDrag's nested loop.
            QTimer::singleShot(0, qApp, [owner, formats, preview] {
                if (!owner) return;
                if (!(QGuiApplication::mouseButtons() & Qt::LeftButton)) {
                    owner->finish(Qt::IgnoreAction);
                    return;
                }
                auto *mime = new QMimeData;
                for (auto it = formats.cbegin(); it != formats.cend(); ++it)
                    mime->setData(it.key(), it.value().toByteArray());
                // The application outlives a reloaded plugin and its source surface.
                auto *drag = new QDrag(qApp);
                drag->setMimeData(mime);
                drag->setPixmap(preview);
                drag->setHotSpot(QPoint(24, 24));
                owner->m_drag = drag;
                DragReleaseFilter filter;
                QTimer::singleShot(0, &filter, [&filter] { qApp->installEventFilter(&filter); });
                const auto action = drag->exec(Qt::CopyAction, Qt::CopyAction);
                qApp->removeEventFilter(&filter);
                if (owner) owner->finish(action);
            });
        }, Qt::SingleShotConnection);
    }

signals:
    void activeChanged();
    void finished(int action);

private:
    void finish(Qt::DropAction action) {
        m_drag = nullptr;
        m_active = false;
        emit activeChanged();
        emit finished(int(action));
    }
    bool m_active = false;
    QPointer<QDrag> m_drag;
    QSharedPointer<QQuickItemGrabResult> m_grab;
};

class NativePlugin final : public QQmlExtensionPlugin {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlExtensionInterface_iid)
public:
    void registerTypes(const char *uri) override {
        qmlRegisterType<NativeDrag>(uri, 1, 0, "NativeDrag");
    }
};

#include "drag.moc"
