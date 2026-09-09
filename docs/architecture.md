# Architecture

`Service.qml` is an Omarchy `service` entry point. One `ShelfStore` owns session
contents; `Variants` creates a `ShelfWindow` for each display. Removing a display
destroys its surface without destroying the store. Workspace changes do neither.

The layer-shell surface has no exclusive zone. Its input region covers the narrow
edge landing area and, while open, the shelf itself. Everything outside those
regions passes through. Qt `DropArea` owns incoming offers; an actual mouse press
and movement starts a Qt native `QDrag` for pickup. There is no compositor polling,
global drag hook, input injection, clipboard access, or companion daemon in the
plugin. The virtual pointer under `tests/` is only an opt-in test driver.

`Payload.js` snapshots portable formats into ArrayBuffers while the drop offer is
valid. It retains original encodings for outbound `QMimeData`. File URIs are
references, never reads or copies of the source file's contents. Preview text is
plain text. No dropped value becomes a command, QML, HTML, or executable code.
Copy is the only accepted and advertised action. Process-local transfer tokens
and cut markers are not replayed. A destination still controls how it interprets
its chosen MIME type.

`ShelfStore.qml` owns a stable ListModel and a separate payload collection.
Changing metadata or order does not recreate every drag source. Removal and clear
are disabled while a native drag owns an item. Source data remains after success
or cancellation; oShelf does not infer that a receiving app has saved the data.

The only child command is `python3 scripts/metadata.py`. Its argv is fixed, paths
arrive as bounded JSON on stdin, and it only stats the provided local references.
Requests are serialized with a two-second process deadline. It distinguishes
folders, unavailable references, and a small set of raster filename extensions.
Canvas decodes thumbnail images with a bounded requested display size and handles
errors without emitting source URLs through the QML Image diagnostic path.
No thumbnail database or content file is written.

Memory budgets bound retained offered bytes, not total process RSS. Preview
strings, image decoding, Qt's transfer buffers, and container overhead use extra
memory. Qt receives a format before exposing its size to QML, and a stalled source
can stall Qt's transfer machinery. These are limitations of the native QML DnD
path, not security isolation guarantees. The plugin runs in the shell's process.

No pinning or persistence is implemented. Session memory provides a predictable
lifetime with no stale payload files. Shell hot reload deliberately clears it.

`native/drag.cpp` owns the outbound drag and its MIME data independently of the
card. It queues native execution outside QML signal evaluation and cancels when
the owning component is destroyed. Qt Wayland owns QDrag until deferred MIME
sends finish. A temporary Qt event filter during this drag prevents a queued
mouse release from ending Qt’s drag loop before Wayland’s drop/finish events;
it neither observes nor intercepts drags from other processes. The filter is
removed on return. This avoids destroying
a Qt Quick attached Drag while execution or data delivery is still in flight.
The native component is built locally against the installed Qt version.
