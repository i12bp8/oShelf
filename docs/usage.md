# oShelf

**Park anything. Pick it up anywhere.**

A small, temporary shelf at an edge of your Omarchy desktop. Drop something
there, switch context, and drag it into another application.

- Files and folders stay where they are; cards carry references.
- Multiple files travel together in one card.
- Images get thumbnails, links get domain previews, and text stays readable.
- Portable MIME formats retain their original bytes, including binary data.
- One shelf across monitors and workspaces. No bar widget or permanent sidebar.
- Current Omarchy colors and typography. No settings required.
- Search filenames, paths, domains, and snippets; switch to compact cards for a busy shelf.
- Keep the shelf open while working, and undo accidental removal or clearing.
- Choose a left or right panel, or a horizontal bottom tray, with your own size and hover behavior.

## Install

Requires **Omarchy Quattro with its Quickshell plugin host**, Qt 6.8 or newer,
and Python 3 (included with Omarchy). Building the small native Qt drag component
requires `gcc`, `make`, `pkgconf`, `qt6-base`, and `qt6-declarative`. No extra Python
packages or privileged installer. Earlier Omarchy releases without the shell plugin host are unsupported.

```sh
omarchy plugin add https://github.com/i12bp8/oShelf
make -C ~/.config/omarchy/plugins/io.github.i12bp8.oshelf
omarchy plugin enable io.github.i12bp8.oshelf
```

After plugin or Qt updates, rebuild with `make` in the installed directory and restart
the shell after finishing any active transfer.

For a local checkout, run `./scripts/install.sh`. It validates and copies the
runtime files and the locally built native component into the user plugin directory, then enables the plugin through
Omarchy. It refuses to replace an existing installation.

Remove it with:

```sh
omarchy plugin remove io.github.i12bp8.oshelf
```

Or run `./scripts/uninstall.sh`. No shortcuts, persistent payload files, or background
service remain. Your optional `~/.config/omarchy/oshelf.json` preferences are kept
for a future reinstall; remove that file separately if you want to forget them.

## Carry something

1. Drag toward the edge handle (middle of the right screen edge by default).
2. Move into the shelf and release.
3. Switch workspace or application. Hover at the same edge to reopen it.
4. Drag a card into the destination.

Drag cards onto one another to reorder. Hover or focus a card to reveal **Remove**.
**Clear** empties the shelf. Pickup uses copy semantics and keeps the card until
you remove it; original files are never moved or deleted.

Use the search field (**Ctrl+F**) to find cards. Searches match all typed words,
regardless of case, including local paths. **Enter** focuses the first matching
card; **Escape** clears the search before closing. Dropping a new item clears the
search and scrolls to its card. **Compact view** hides large previews to fit more
items; **Keep open** disables automatic collapse until you turn it off. The Close
button and Escape still close the shelf. These view choices last for the session,
independently on each monitor.

## Make it yours

Open the sliders icon beside the close button, or run `omarchy-shell oshelf settings`.
Choose **Left**, **Right**, or **Bottom**. Bottom placement presents the cards in a
horizontal tray; scrolling and keyboard paging follow the tray direction.

The settings panel includes a preview of your activation zone, and these bounded
controls. Dimensions are logical pixels, so they follow display scaling.

| Setting | Default | Allowed range |
| --- | --- | --- |
| Side popup width / height | 360 / 520 px | 360–640 / 460–1000 px |
| Bottom popup width / height | 680 / 400 px | 560–1400 / 400–800 px |
| Position along the edge | 50% | 10–90% |
| Activation length | 200 px | 80–600 px, at most 80% of the edge |
| Activation depth | 8 px | 4–24 px |
| Hover before opening | 350 ms | 150–1500 ms |
| Delay after leaving | 700 ms | 250–2500 ms |
| Opening animation | 260 ms | 120–420 ms |

Side and bottom sizes are saved separately. Popup dimensions automatically shrink
to leave a 16 px margin on smaller monitors. Settings use their own scrollable
panel, so controls remain reachable regardless of the selected popup size.

**Require a steady hover** is on by default: moving more than 6 px restarts the
opening timer. The edge handle fills as you wait. Turning it off only requires
staying within the zone. Dragging data to the edge and clicking the handle open
immediately. Moving outside the configured zone does not activate the shelf.
Returning to the panel cancels the close timer. Keep-open mode, search focus,
settings, and active transfers keep it open; Escape or Close dismisses it when
no transfer is active. **Reduced motion** removes the panel slide/scale and card
arrival animations. Closing takes three quarters of the chosen animation time.

**Apply** saves preferences for all displays. **Cancel** discards the draft, and
**Defaults** fills in the recommended values for review before applying. Preferences
live in `$XDG_CONFIG_HOME/omarchy/oshelf.json` (normally `~/.config/omarchy/oshelf.json`),
outside the plugin directory, and survive plugin updates. Invalid values are
clamped or replaced with defaults. The JSON contains preferences only, never cards.

## Recovery and keyboard controls

**Undo** restores the last removal or Clear for ten seconds, including the prior
card order. **Ctrl+Z** also restores when the shelf (outside the search field) has
focus. A successful new incoming drop replaces this recovery opportunity;
rejected drops do not. Undo is unavailable during an outgoing drag.

**Escape** collapses. **Tab** focuses controls/cards; **Delete** removes a focused
card; **Ctrl+Up/Down** reorders it; **PageUp/PageDown** scroll; **Ctrl+Backspace**
clears. For an optional launcher or shortcut, use `omarchy-shell oshelf show`.
No shortcut is installed automatically.
In the bottom tray, **Ctrl+Left/Right** also reorders cards.

## What can be carried

| Source | Representation | Transfer |
| --- | --- | --- |
| Local file / folder | Filename / folder card | Original local file URI |
| Multiple local files | One bundle, mini thumbnails for image files | Original URI list |
| PNG, JPEG, WebP data | Thumbnail when small enough | Original encoded image bytes |
| Browser image | Image or domain card, depending on the browser's offer | Offered image bytes and/or URL |
| Web link | Domain and URL | Offered URL and text formats |
| Selected text | Plain text preview | Original text and any portable rich-text formats |
| Other MIME data | Transfer card | Original portable bytes |

Destinations choose the format they understand. Image-only drags do not become
files: file managers that require file URIs may reject them. Carry a saved image
file when you need that behavior. No web requests are made for previews, including
favicons. HTML is carried but never rendered. Process-local Qt, portal, browser
file tokens, and file-manager cut instructions are excluded.

The default landing area is **8 logical pixels deep and 200 pixels long**, centered
on each display's right edge. Placement, size, and timing are configurable as above.
Wayland provides drag events only after entry into that area. It also opens on
ordinary hover; there is no global drag surveillance.
It reserves no desktop space. Adjacent monitor edges may be crossed normally
outside that small landing area.

Contents live in memory until removed, disabled, reloaded, or the shell/session
ends. There is no history or disk persistence. References to moved/deleted files
are marked unavailable when reopened; a destination can still encounter a file
that disappears after that check. Source-owned temporary files remain references.
Removed content remains in memory for the ten-second undo window, or until the
next successful incoming drop or removal replaces it.

Limits: 48 cards, 256 references per card, 16 MiB of MIME bytes per card and 64 MiB
across the shelf. Preview encoding is limited to 2 MiB; larger images still carry
their bytes. Qt receives source data before oShelf can check its size, so these are
retention limits, not a sandbox against a malicious or stalled drag source.

## Development

```sh
make
omarchy plugin validate .
node --test tests/payload.test.cjs
python3 tests/metadata_test.py
```

See [verification](verification.md), [architecture](architecture.md),
and [marketplace preparation](marketplace.md).

![oShelf carrying an image](../preview.png)

MIT licensed. No telemetry, clipboard monitoring, network access, or content logs.
