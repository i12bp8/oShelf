# Marketplace preparation

One plugin lives at the repository root, with a schemaVersion 1 manifest, a
non-reserved namespaced ID, README, MIT license, safe installation/removal, and
explicit dependencies. The plugin requires a local native Qt build and should be listed as manual setup.
Omarchy does not execute build hooks; the README documents the explicit build step.

The expected public repository is `https://github.com/i12bp8/oShelf`. Confirm the
owner and final repository URL before publishing; this checkout does not establish
that a public repository or listing exists. Check permanent ID availability for
`io.github.i12bp8.oshelf` before the first submission.

Suggested category: **Productivity**. Tags: **quickshell, workspaces, system**.
Use a real, content-safe root `preview.png` when available. The README includes
screenshot and GIF placeholders; do not present mockups as verified screenshots.

Before submitting, run `omarchy plugin validate .`, the payload/metadata tests,
and the live transfer tests on the target Omarchy release. Review the exact commit
that will be submitted. Public automated checks and maintainer review determine
acceptance; passing local manifest validation cannot guarantee a listing.

Disclose these capabilities in maintainer notes:

- Overlay layer-shell surfaces with a small masked input region.
- In-memory retention of user-dropped MIME bytes and local file references.
- A locally compiled C++ Qt component for safe native drag lifetime.
- A fixed Python helper for local filesystem metadata; no shell interpolation.
- Local raster thumbnail reads. No network, clipboard, telemetry, or persistent content.
- The opt-in test suite contains a virtual pointer; runtime code never calls it.

Follow the current [submission instructions](https://github.com/omacom/omarchy-plugin-marketplace/blob/main/SUBMISSION.md)
and [security baseline](https://github.com/omacom/omarchy-plugin-marketplace/blob/main/SECURITY.md).
The submission workflow requires the owner to confirm the checklist and approve
the completed submission before an agent opens the marketplace issue.
