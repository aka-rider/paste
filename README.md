# paste

`paste` is a personal encrypted pastebin for aka-rider. The `pb` command turns a
self-contained HTML file into a private link. Anyone with the full link can open
it in a browser. GitHub only ever stores ciphertext.

A link looks like this:

```
https://aka-rider.github.io/paste/#a1b2c3d4e5f6.k9F3...q2Q_-8w
                                    └────┬─────┘└──────┬──────┘
                                     gist id       base64url key
                                                   (64 bytes: enc + mac)
```

The part after `#` is the URL fragment. Browsers never send it to a server, so
only people who have the full link can decrypt the paste.

## Publish

```sh
pb report.html
```

The command prints one line: the private link. Send that link to yourself or
whoever needs to read the page.

## How it works

`pb` encrypts the file, uploads the ciphertext as a secret GitHub gist, and
prints a link with the key in the fragment. The static viewer at
`https://aka-rider.github.io/paste/` (GitHub Pages, `index.html` in this repo)
reads the fragment, fetches the gist's raw content, verifies the HMAC, decrypts
with WebCrypto, and renders the HTML. There is no backend and no server-side
state.

Wire format:

- Key: 64 random bytes. First 32 bytes are the AES-256 key (`enc`). Last 32
  bytes are the HMAC key (`mac`).
- Blob: `base64(iv || ciphertext)` where `iv` is a random 16-byte AES-CTR IV.
- Gist content: `<blob>.<hex hmac>`, where the HMAC-SHA256 is computed over
  `iv || ciphertext` using the `mac` key (encrypt-then-MAC).
- Gist: created with `gh gist create`, secret (unlisted, not indexed or linked
  from any profile page).
- Fragment: `<gist-id>.<base64url(enc || mac)>`. The fragment never leaves the
  browser.

## Threat model

- A secret gist is not access-controlled. It is an unguessable URL. Anyone who
  gets the full link (gist ID and key) can decrypt and read the paste.
- The ciphertext is public in principle. GitHub could serve it to anyone who
  guesses or finds the gist ID, but without the key they get random bytes.
- GitHub sees only ciphertext. It never sees the plaintext or the key.
- Whatever chat channel or app you use to send the link already saw the
  plaintext when you created it. `paste` protects the paste in transit and at
  rest on GitHub, not from the sender.
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

```sh
git clone https://github.com/aka-rider/paste ~/Developer/paste
cd ~/Developer/paste
ln -s "$PWD/bin/pb" ~/.local/bin/pb
gh auth login
ln -s "$PWD/skill" ~/.claude/skills/paste
```
