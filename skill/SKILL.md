---
name: to-html
description: Turn HTML into a private encrypted link readable in any browser, on any device. Use whenever HTML is produced that the user should read — a report, plan, lesson, mockup, or dashboard — instead of leaving a file path on disk, or when the user says "paste it" / "make it readable".
---

1. Write the HTML wherever it naturally belongs. A stylesheet, a script,
   images, and links to sibling `.html` pages are fine — local relative
   references are packaged automatically. Layout, styling, and file structure
   are yours to decide; this skill does not care.
2. Run `pb <entry.html>` (on PATH). It prints exactly one line: the link.
3. Give the user that link. Do not give them a file path.
4. Absolute URLs (`https:`, `data:`, …) stay external. The reader's browser
   fetches those directly, so the page must still work over the internet.
5. Each publish is a frozen snapshot. If you edit the file, run `pb` again —
   the new link shows the edit; the old link keeps showing the old version.
6. If `pb` fails, show the user its stderr. Do not retry blindly. Common
   causes: `gh` not authenticated (`gh auth login`), file missing or
   unreadable.
