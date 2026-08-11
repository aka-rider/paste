---
name: paste
description: Publish a self-contained HTML file as a private encrypted link readable in any browser. Use when the user asks to make an HTML report/plan/mockup readable over the internet, share a page to their phone, or says "paste it" / "make it readable".
---

1. Produce a fully self-contained HTML file. Inline all CSS and JS. Inline
   images as `data:` URIs. No external requests. Use a responsive,
   mobile-first layout. Set a proper `<title>`. Write it to a scratch or temp
   location.
2. Run `pb <file>` (on PATH). It prints one line: the private link.
3. Give the user that link as the deliverable. Mention they can export the
   paste to PDF from the browser's print or share menu if they need to send
   it to someone else.
4. If `pb` fails, show the user its stderr. Do not retry blindly. Common
   causes: `gh` not authenticated (`gh auth login`), file missing or
   unreadable.
