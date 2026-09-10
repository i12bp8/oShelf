# Website

The public landing page lives in `site/`, independently of the plugin runtime.
It uses plain HTML, CSS, and JavaScript: no build process, external fonts, analytics,
or third-party scripts. The demo is a scripted animation of an Omarchy desktop using
oShelf; it only handles predefined sample identifiers and never reads or uploads
dropped files. Copying installation commands uses the clipboard only after clicking
Copy.

The animation runs on a fixed 1920 × 1080 desktop scaled to fit the page and
reproduces the Vantablack Omarchy desktop: the top bar, the Omarchy wallpaper, a
full-screen tiled Files window, and the oShelf panel with the plugin’s real layout.
A synthetic cursor parks `cover.png` and `omarchy.org` on the shelf, switches
workspace, and delivers both into a second tiled Files window. The timeline is a
pure function of time, so play, pause, replay, and the scrubber seek to any frame.
Autoplay starts when the stage scrolls into view.

The visual design uses an OLED-black page, bold sans-serif headings, white controls,
and gray surfaces. `site/wallpaper.png` is the Omarchy logo background from the
Omarchy project (MIT). The page background is pure black.

Serve locally with `python3 -m http.server 8000 --directory site`. GitHub Pages is
published from the `gh-pages` branch, which contains only the contents of `site/`.
To update it, publish the reviewed site files to that branch after updating main.

## Browser verification

Install Playwright outside the runtime, then run:

```sh
npm install --prefix /tmp/oshelf-site-tools playwright
OSHELF_PLAYWRIGHT=/tmp/oshelf-site-tools/node_modules/playwright/index.mjs node tests/site.mjs
```

The test uses installed Chromium, creates a local server, and seeks the scripted
timeline through its key frames (closed shelf, two cards parked, workspace switch,
both deliveries), checks pause and scrubber behavior, autoplay on scroll, responsive
shelf geometry at 320, 390, 700, 768, 1024, and 1440 px, reduced motion, and
JavaScript errors. Set `OSHELF_SITE_CAPTURE=1` to regenerate `site/demo.png`,
`site/social.png`, and temporary review screenshots.

The social preview is a screenshot of this browser demo. The README shows the
native plugin capture `preview.png`, which also serves the marketplace metadata.
Do not present the simulation as a native screenshot.
