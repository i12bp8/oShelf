# Architecture

`Service.qml` is an Omarchy `service` entry point. One `ShelfStore` owns session
contents; `Variants` creates a `ShelfWindow` for each display. Removing a display
destroys its surface without destroying the store. Workspace changes do neither.

The layer-shell surface spans the display's available area with no exclusive zone.
Its input region covers the narrow
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

`ShelfPreferences.qml` loads and saves only bounded preferences in the user's
Omarchy config directory, through Quickshell FileView. `Preferences.js` validates
types, drops unknown properties, and clamps numeric ranges. The file sits outside
the watched plugin runtime directory, so changing preferences does not reload or
empty the shelf. A draft settings view commits on Apply. Missing or malformed
preferences retain safe defaults (or the last valid in-memory values); save failures
are reported in the settings view.

The store shares placement, dimensions, and hover policy across windows. Each
window owns its search query, compact layout, and keep-open preference.
Search hides nonmatching delegates without rebuilding the store's model, preserving
native drag sources. It matches all words across plain titles, details, kinds, and
paths. Incoming additions reset search and scroll to the new card.

The bottom layout uses the same ListModel and native drag components, in a horizontal
ListView. An input mask includes only the activation rectangle and, while open,
the rounded panel; unrelated desktop input passes through. Popup dimensions are
clamped to the monitor with a 16 px margin. Pointer dwell uses local HoverHandler
events and a timer. In steady mode, movement beyond 6 logical pixels from the dwell
origin resets it. Drag entry bypasses dwell. No compositor polling is used at runtime.
An eased progress value coordinates panel opacity, slide, and scale; reduced motion
skips panel and card spatial animations. Effects are enabled only on a visible panel.

Removal and clear keep one shallow snapshot of the prior order for ten seconds.
Shared payload objects are not copied. A subsequent removal replaces the snapshot;
a successful incoming capture discards it before retaining the new item. Thus
undo does not add another shelf-sized payload budget. Undo restores the model,
recomputes its byte budget, and refreshes file metadata. Native drags block undo,
removal, and clearing. No recovery survives reload or session exit.

`native/drag.cpp` owns the outbound drag and its MIME data independently of the
card. It queues native execution outside QML signal evaluation and cancels when
the owning component is destroyed. Qt Wayland owns QDrag until deferred MIME
sends finish. A temporary Qt event filter during this drag prevents a queued
mouse release from ending Qt’s drag loop before Wayland’s drop/finish events;
it neither observes nor intercepts drags from other processes. The filter is
removed on return. This avoids destroying
a Qt Quick attached Drag while execution or data delivery is still in flight.
The native component is built locally against the installed Qt version.
