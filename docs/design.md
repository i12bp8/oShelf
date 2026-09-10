# Everyday oShelf

The shelf is a temporary place between applications. Its everyday value is a short
loop: collect something, switch context, deliver it. Files, links, images, and
developer snippets should all follow that same loop.

## Implemented in this pass

- A stable panel with separate identity, search, controls, content, and recovery areas.
- Theme-derived card surfaces, accent labels, hover outlines, and drop feedback.
- Multiword search over card text, domains, and local file paths.
- Compact cards for a crowded shelf, preserving the original payloads and order.
- Keep-open mode for repeated transfers, with explicit close always available.
- Ten-second undo for removal and clearing, within the existing retention budget.
- New drops clear search and scroll into view, so arrivals are easy to locate.
- Left/right panels and a horizontal bottom tray, with independently saved sizes.
- An in-panel settings view with bounded activation geometry, dwell and close
  delays, steady-hover behavior, and reduced motion.
- Coordinated fade, slide, and scale, a dwell-progress handle, softer surfaces,
  consistent line icons, and a restrained theme-derived header wash.

## Next product priorities

1. **Keyboard delivery.** Investigate explicit copy and open actions for each
   representation. Preserve binary MIME data, handle missing references, and make
   it clear when an action changes the clipboard or launches an application.
2. **Selection and bundles.** Select several cards and deliver compatible local
   file references as one drag. Mixed binary/text payloads need an explicit rule;
   silently choosing one card's data would lose information.
3. **Preview on demand.** Inspect a longer snippet, image, or file bundle without
   making every card larger. Escape should return to the same focused card.
4. **Deliberately saved items.** Decide whether persistent snippets belong in a
   separate saved section. Persistence needs explicit lifetime, cleanup, stale
   reference handling, and migration behavior before implementation.
5. **Release readiness.** Repeat native transfer tests against the new layout;
   cover browser and GTK sources, multiple monitors, small screens, theme changes,
   keyboard-only use, and font scaling before presenting this as broadly tested.

Keep the entry point quiet and discoverable. Routine use should require no setup.
Expose advanced actions when a user needs them, while preserving the direct
drag-and-drop path. Measure success by how quickly users can park, find, and
deliver something, and whether failed or accidental actions are recoverable.
