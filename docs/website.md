# Website

The public landing page lives in `site/`, independently of the plugin runtime.
It uses plain HTML, CSS, and JavaScript: no build process, external fonts, analytics,
or third-party scripts. The demo handles only predefined sample identifiers and
never reads or uploads dropped files. Copying installation commands uses the
clipboard only after clicking Copy.

The desktop demo supports native browser dragging, button alternatives for touch
and keyboard, workspace switching, three shelf placements, and a cancellable guided
flow. It is explicitly labeled as a browser simulation, not a native OS recording.
The narrow-screen demo stacks its windows for usable touch targets.

Serve locally with `python3 -m http.server 8000 --directory site`. GitHub Pages is
published from the `gh-pages` branch, which contains only the contents of `site/`.
To update it, publish the reviewed site files to that branch after updating main.

## Browser verification

Install Playwright outside the runtime, then run:

```sh
npm install --prefix /tmp/oshelf-site-tools playwright
OSHELF_PLAYWRIGHT=/tmp/oshelf-site-tools/node_modules/playwright/index.mjs node tests/site.mjs
```

The test uses installed Chromium, creates a local server, and verifies dragging
in/out, click delivery, retained cards, placement, the guided tour, responsive
layouts, reduced motion, and JavaScript errors. Set `OSHELF_SITE_CAPTURE=1` to
regenerate `site/demo.png`, `site/social.png`, and temporary review screenshots.

README and social previews are screenshots of this browser demo. `preview.png`
at repository root remains the native plugin capture used by its marketplace
metadata. Do not present the simulation as a native screenshot.
