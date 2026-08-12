# paste

`paste` is a personal encrypted pastebin. The `pb` command turns an HTML page,
and everything it references locally, into one private link. Anyone with the
full link can open it in a browser, on any device. GitHub only ever stores
ciphertext.

A link looks like this:

```
https://iurii.net/paste/#a1b2c3d4e5f6.k9F3...q2Q_-8w
                          └────┬─────┘└──────┬──────┘
                           gist id       base64url key
                                         (64 bytes: enc + mac)
```

The domain and path above are an example. Your own links use whatever
address your fork's GitHub Pages site is served from — see "Setup on a new
machine". The part after `#` is the URL fragment. Browsers never send it to a
server, so only people with the full link can decrypt the paste. On load, the
viewer moves the fragment from the address bar into `sessionStorage`, keeping
the key out of browser history and away from any analytics script your Pages
host might inject. Reload still works; to reopen later, use the link from
the chat.

## Publish

```sh
pb entry.html
```

`pb` follows every local relative reference from `entry.html` — stylesheets,
scripts, images, `url()` references inside CSS, and links to sibling local
`.html` pages — and bundles all of it into one encrypted paste. Absolute URLs
(`https:`, `data:`, …) are left alone; the reader's browser fetches those
directly, so the page still needs the internet for them.

The command prints one line: the private link. Send that link to yourself or
whoever needs to read the page.

## How it works

`pb` hands the entry file to a bundler, which walks the local references
above and builds one JSON document describing every file it found. `pb`
encrypts that document as a single blob and uploads it as one secret GitHub
gist, then prints a link with the key in the fragment.

Each publish is a new, immutable gist. Publish a page together with its
stylesheet, edit the stylesheet, publish again: the first link still shows
the first stylesheet, the second link shows the second. One bundle cannot see
another bundle's files. This is deliberate — a link is a frozen snapshot,
never a live view of your working tree. There is no deduplication: every
publish creates a new gist, even when nothing changed.

`pb` derives the viewer link itself, from the repo's GitHub Pages settings:
`gh api repos/<owner>/<name>/pages --jq .html_url`, with `<owner>` and
`<name>` read from the repo's own git remote. Set `PB_VIEWER_URL` to override
it.

The static viewer (`index.html` in this repo, served by GitHub Pages) reads
the fragment, fetches the gist by ID, verifies the HMAC, and decrypts with
WebCrypto. It inlines each page's local assets and renders the result inside
a sandboxed `<iframe sandbox="allow-scripts allow-popups">`, so the paste runs
on an opaque origin and cannot reach the key. Clicking a link to another page
in the same bundle re-renders it from the already-decrypted bundle, with no
new fetch; that navigation does not push browser history, so the back button
skips it. Pastes published before bundles existed were raw HTML — the viewer
still renders those directly.

There is no backend and no server-side state.

## Bundle format

```json
{
  "entry": "lessons/0001-intro.html",
  "files": {
    "lessons/0001-intro.html": { "type": "text/html", "text": "..." },
    "assets/course.css":       { "type": "text/css",  "text": "..." },
    "assets/dot.png":          { "type": "image/png", "b64":  "..." }
  }
}
```

Paths are relative to the bundle root: the common ancestor of every file the
walk found. Text files carry their content in `text`; binary files (images,
fonts) carry base64 in `b64`. This document, as a whole, is what gets
encrypted and stored as the gist.

## Wire format

- Key: 64 random bytes. First 32 bytes are the AES-256 key (`enc`). Last 32
  bytes are the HMAC key (`mac`).
- Blob: `base64(iv || ciphertext)` where `iv` is a random 16-byte AES-CTR IV
  and the plaintext is the bundle document above.
- Gist content: `<blob>.<hex hmac>`, where the HMAC-SHA256 is computed over
  `iv || ciphertext` using the `mac` key (encrypt-then-MAC).
- Gist: created with `gh gist create`, secret (unlisted, not indexed or
  linked from any profile page).
- Fragment: `<gist-id>.<base64url(enc || mac)>`. The fragment never leaves
  the browser.

## Threat model

- A secret gist is not access-controlled. It is an unguessable URL. Anyone
  who gets the full link (gist ID and key) can decrypt and read the paste.
- The ciphertext is public in principle. GitHub could serve it to anyone who
  guesses or finds the gist ID, but without the key they get random bytes.
- GitHub sees only ciphertext. It never sees the plaintext or the key.
- The rendered paste runs inside a sandboxed iframe on an opaque origin. It
  cannot read the key held in the viewer's `sessionStorage`.
- Opening a paste reads the gist through GitHub's unauthenticated API, capped
  at 60 requests per hour per IP. Hitting that cap blocks new opens from the
  same network until it resets; the viewer reports this case distinctly from
  other errors.
- Whatever chat channel or app you use to send the link already saw the
  plaintext when you created it. `paste` protects the paste in transit and
  at rest on GitHub, not from the sender.
- This is not for high-stakes secrets: passwords, private keys, financial
  data, anything you would not want exposed if a link leaked. Use a real
  secrets manager for that.

## Housekeeping

Pastes are throwaways. Delete them when done.

```sh
gh gist list
gh gist delete <id>
```

## Setup on a new machine

Fork this repo, then enable GitHub Pages on your fork (Settings → Pages),
pointing it at the branch and folder that contain `index.html`. `pb` reads
the resulting URL on its own; you do not set it anywhere.

```sh
git clone https://github.com/<you>/paste.git
cd paste
ln -s "$PWD/bin/pb" ~/.local/bin/pb
gh auth login
ln -s "$PWD/skill" ~/.claude/skills/to-html
```
