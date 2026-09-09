# Verification

Tested on 9 September 2026 with Omarchy Quattro, Hyprland 0.56.2 and Qt 6.11.2,
on a 1920×1080 display at 1.25 scale.

## Automated checks

`make check` builds the native component, runs the official Omarchy manifest
validator, and exercises payload validation, byte preservation, encoded and
hostile filenames, remote file URI rejection, memory limits, metadata failures,
and installation into a temporary configuration directory. The install test
stubs Omarchy's IPC commands and verifies overwrite refusal; it does not change
the live desktop.

The plugin was also installed and enabled in the live Omarchy host. Its IPC and
`oshelf` layer surface were verified in the existing shell process.

The installed `qmllint` can check the QML with Omarchy's `Commons` module available
under the `qs` import namespace. Its Quickshell type metadata reports two known
static-analysis warnings: `PanelWindow` creatability and `QProcess::ExitStatus`.
The live engine loads those types successfully. No warning categories are hidden
in the repository.

## Live Wayland tests

The opt-in suite opens a separate Qt source/receiver and an isolated Quickshell
shelf. It uses a test-only virtual pointer, switches to an unused workspace and
back, restores focus/pointer position, and removes its temporary files/windows.
Do not interact with the pointer during this test. It currently requires one
unrotated display and a visible test window.

Build the test tools using the official wlr virtual-pointer protocol XML:

```sh
make
./tests/build.sh /path/to/wlr-virtual-pointer-unstable-v1.xml
node tests/live.mjs "$PWD/build/tests"
```

The protocol source is available from
[wlr-protocols](https://gitlab.freedesktop.org/wlroots/wlr-protocols/-/blob/master/unstable/wlr-virtual-pointer-unstable-v1.xml).
The test does not download or execute remote code. Development dependencies:
C/C++ compilers, Qt Widgets, libwayland-client, wayland-scanner, Node.js, grim,
wtype, and Hyprland IPC. These are not all runtime plugin dependencies.

Cases include native round trips for text, a folder, a file with spaces/Unicode
and shell metacharacters, a file bundle, PNG data, invalid PNG data, and a URL.
The receiver compares **every original MIME byte**, including a binary custom
format with NUL and non-UTF8 bytes. The suite checks missing-reference detection,
workspace persistence, repeat drops, native card reordering, Escape cancellation,
and reload during a held native drag. The image cases capture a synthetic-content
screenshot and check that neither the malformed payload nor its base64 appears
in the shell log.

The native component was added after the reload test exposed Qt Quick attached
Drag lifetime failures. Its queued QDrag operation survives destruction of the
QML caller, cancels on unload, and keeps MIME data alive for Wayland's deferred
reads. Regression tests keep this lifecycle in scope.

## Remaining compatibility coverage

The automated receiver is a separate Qt Widgets process. Real browser image
sources, GTK file managers, sandboxed portal offers, multi-monitor hotplug, touch,
and every destination's preferred MIME type have not been exhaustively tested.
A successful Qt round trip is not a claim of universal application compatibility.
Before a marketplace release, test the applications used by the intended audience.

The native library is built against the installed Qt; rebuild after Qt upgrades.
Do not replace a loaded shared library in place. The Makefile links into `build/`
and renames the result, and the README directs users to restart after updates.
