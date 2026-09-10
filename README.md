<div align="center">

<img src="site/icon.svg" width="64" height="64" alt="oShelf logo">

# oShelf

### A little room between apps.

Park that file. Save your train of thought. Pick it up where you need it.

**[Watch the demo →](https://i12bp8.github.io/oShelf/)** · [Install](#install) · [Make it yours](#make-it-yours) · [User guide](docs/usage.md)

[![MIT License](https://img.shields.io/badge/license-MIT-ffffff?style=flat-square&labelColor=000000)](LICENSE)
[![Omarchy Quattro](https://img.shields.io/badge/made_for-Omarchy_Quattro-ffffff?style=flat-square&labelColor=000000)](https://omarchy.org/)
[![Website](https://img.shields.io/badge/play-the_demo-ffffff?style=flat-square&labelColor=000000)](https://i12bp8.github.io/oShelf/)

[![oShelf carrying an image on an Omarchy desktop](preview.png)](preview.png)

<sub>The real plugin on an Omarchy desktop. [Watch the scripted browser demo →](https://i12bp8.github.io/oShelf/)</sub>

</div>

---

You have the file. The destination is three windows and a workspace away.

**oShelf gives you somewhere to put it down.** A small temporary shelf for files,
images, links, and text, always within reach at your desktop edge. Drop something
in, switch context, and drag it into place.

No extra window to manage. No folder to clean up. Just a little less friction.

## Park. Switch. Pick up.

1. **Park** — drag toward the edge handle. The shelf opens. Drop your item.
2. **Switch** — change apps, workspaces, or monitors. Your shelf comes with you.
3. **Pick up** — drag the card into its destination. It stays on the shelf for another trip.

A screenshot headed for a message. A folder moving between projects. A snippet
you need on the other side of a context switch. Same simple flow.

| A small feature | A surprisingly useful detail |
| --- | --- |
| **Carry the whole bundle** | Multiple files travel together in one card. |
| **See what you parked** | Image thumbnails, folder cards, domain previews, readable text. |
| **Find it fast** | Search filenames, local paths, links, and snippets. |
| **Make a little more room** | Compact cards and a keep-open toggle for busy sessions. |
| **Undo the oops** | Restore Remove or Clear for ten seconds. |
| **Feel at home** | Your Omarchy colors and typography, soft motion, and reduced-motion support. |
| **Choose your edge** | Left, right, or a horizontal bottom tray. |

## Install

Requires **Omarchy Quattro with the Quickshell plugin host**, **Qt 6.8+**, and
**Python 3**. The native drag component is built locally; build dependencies are
`gcc`, `make`, `pkgconf`, `qt6-base`, and `qt6-declarative`.

```sh
omarchy plugin add https://github.com/i12bp8/oShelf
make -C ~/.config/omarchy/plugins/io.github.i12bp8.oshelf
omarchy plugin enable io.github.i12bp8.oshelf
```

**Then hover at the middle of the right screen edge.** Your shelf is waiting.

For a local checkout, use `./scripts/install.sh`. It builds and validates the
plugin, copies the runtime files, and enables it. It refuses to overwrite an
existing installation.

After plugin or Qt updates, rebuild in the installed directory and restart the
shell after finishing any active transfer. Reloading clears temporary shelf items.

## Uninstall

```sh
omarchy plugin remove io.github.i12bp8.oshelf
```

Or run `./scripts/uninstall.sh` from a local checkout. No shortcuts, persistent
payload files, or background service remain. Your optional
`~/.config/omarchy/oshelf.json` preferences are kept for a future reinstall;
remove that file separately if you want to forget them.

<details>
<summary><strong>Optional shortcuts</strong></summary>

Open the shelf from a launcher or your own keybinding:

```sh
omarchy-shell oshelf show
omarchy-shell oshelf hide
omarchy-shell oshelf settings
```

No shortcut is installed automatically.

</details>

## Make it yours

Click the **sliders icon** in the shelf. Choose where it lives and how it feels.

- **Placement:** left, right, or bottom.
- **Size:** separate width and height for side panels and the bottom tray.
- **Activation:** choose the zone’s length, depth, and position along the edge.
- **Timing:** tune hover-to-open and leave-to-close delays.
- **Motion:** choose animation duration, steady-hover behavior, and reduced motion.

Defaults are deliberately small: **360 × 520** for the sides and **680 × 400** for
the bottom. Sizes automatically fit smaller displays. Settings have bounded ranges,
a zone preview, and Apply / Cancel controls.

Preferences survive updates. Shelf contents stay temporary.
[See every setting and its limits →](docs/usage.md#make-it-yours)

## A pocket, not an archive

**Your files stay where they are.** oShelf carries references, never moves or
deletes originals, and uses copy semantics when you pick something up.

**Your shelf lives in session memory.** No payload history or persistent content
files. Disable, reload, or end the shell session and it empties. Removed content
remains briefly available for undo.

**Your data stays local.** No network requests, telemetry, clipboard monitoring,
or rendered HTML. Image previews come from offered data or local raster files.

Destinations choose the formats they accept. Image-only drags are not converted
into files; use a saved image when the destination needs a file URI. Browser,
GTK, portal, and multi-monitor compatibility is not exhaustively tested.

<details>
<summary><strong>Keyboard flow</strong></summary>

| Key | Action |
| --- | --- |
| Ctrl+F | Find something on your shelf |
| Enter in search | Focus the first matching card |
| Escape | Clear search, leave settings, or close |
| Tab | Move between controls and cards |
| Delete | Remove the focused card |
| Ctrl+Z | Undo removal/clear outside the search field |
| Ctrl+Up / Down | Reorder cards |
| Ctrl+Left / Right | Reorder in the bottom tray |
| PageUp / PageDown | Scroll |
| Ctrl+Backspace | Clear the shelf |

</details>

<details>
<summary><strong>What can it carry?</strong></summary>

| Drop | What travels |
| --- | --- |
| Local file or folder | Original local file URI |
| Multiple local files | Original URI list, bundled into one card |
| PNG, JPEG, WebP data | Original encoded bytes |
| Browser image | Image and/or URL formats offered by the browser |
| Web link | Offered URL and text formats |
| Selected text | Plain text and portable rich-text formats |
| Other portable MIME data | Original bytes, including binary formats |

Limits: 48 cards, 256 references per card, 16 MiB of MIME bytes per card, and
64 MiB across the shelf. These bound retained payloads, not Qt’s initial data
transfer or total process memory. See the [user guide](docs/usage.md) for details.

</details>

## Built in the open

oShelf is an independent community plugin, MIT licensed.

```sh
make check
```

This builds the native component, validates the Omarchy manifest, and runs payload,
preferences, metadata, and installation checks. The opt-in Wayland tests exercise
real native drag round trips, hover behavior, and drag lifetime.

[Architecture](docs/architecture.md) · [Verification & compatibility](docs/verification.md) ·
[Website development](docs/website.md) · [Product direction](docs/design.md)

Found a rough edge? [Open an issue](https://github.com/i12bp8/oShelf/issues).
Include your Omarchy/Qt versions, source and destination apps, and steps to reproduce.
Use sample data in screenshots and logs.

---

<div align="center">

**Small tool. Hard to go back.**

If oShelf finds a place in your day, [give it a star](https://github.com/i12bp8/oShelf)
or show someone your new desktop habit.

[Watch it in your browser →](https://i12bp8.github.io/oShelf/)

</div>
