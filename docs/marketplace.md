# Marketplace submission

The plugin lives at the repository root: `manifest.json` (schemaVersion 1),
README, MIT license, and a real UI capture as `preview.png`. Omarchy runs no
build hooks, so the local native Qt build step documented in the README is
required before the plugin can run.

Listing metadata:

- Repository: `https://github.com/i12bp8/oShelf`
- ID: `io.github.i12bp8.oshelf` (namespaced, not used by other listings)
- Category: **Productivity**
- Tags: **quickshell, workspaces, system**

Before submitting, run `omarchy plugin validate .`, the payload/metadata tests,
and the live transfer tests on the target Omarchy release. Public automated
checks and maintainer review decide acceptance; passing local validation cannot
guarantee a listing.

Disclose these capabilities in the maintainer notes:

- Overlay layer-shell surface with a small masked input region.
- In-memory retention of user-dropped MIME bytes and local file references.
- A locally compiled C++ Qt component for safe native drag lifetime.
- A fixed Python helper for local filesystem metadata; no shell interpolation.
- Local raster thumbnail reads and a bounded preferences-only JSON file under the
  user's Omarchy config directory. No network, clipboard, telemetry, or persistent payloads.
- The opt-in test suite contains a virtual pointer; runtime code never calls it.

Follow the current [submission instructions](https://github.com/omacom/omarchy-plugin-marketplace/blob/main/SUBMISSION.md)
and [security baseline](https://github.com/omacom/omarchy-plugin-marketplace/blob/main/SECURITY.md).
The submission workflow requires the owner to confirm the checklist and approve
the completed submission before an agent opens the marketplace issue.
