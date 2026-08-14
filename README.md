# paste

`paste` is a personal encrypted HTML pastebin.

This is for when you chat with an LLM, or use Matt Pocock's `/teach` skill, and you want to read the HTML on your mobile, tablet, or another PC.

You say `/to-html` and you get a link. The HTML is encrypted and stored as Gist on GitHub. The link contains the key, so anyone with the link can decipher and read the HTML page.

```
https://<you>.github.io/paste/#a1b2c3d4e5f6.k9F3...q2Q_-8w
                               └────┬─────┘ └─────┬──────┘
                                 gist id       base64url key
                                               (64 bytes: enc + mac)
```

`pb` requires the `gh` CLI (authenticated), `python3`, `openssl`, and `xxd`, and it must run from a clone with an `origin` remote.

## Publish

```sh
pb entry.html
```

`pb` follows every local relative reference from `entry.html` — stylesheets, scripts, images (including `srcset`), `url()` references inside CSS, and links to any local `.html` page, in subdirectories or parent directories, not just siblings — bounded by the repo root — and bundles all of it into one encrypted paste.

The command prints one line: the private link.

## Housekeeping

Pastes are throwaways. Delete them when done.

```sh
gh gist list
gh gist delete <id>
```

## Setup on a new machine

Fork this repo, then enable GitHub Pages on your fork (Settings → Pages), pointing it at the branch and folder that contain `index.html`. The fork must be your own repo: the Pages lookup (`gh api repos/<owner>/<repo>/pages`) needs admin access.
`pb` reads the resulting URL on its own; you do not set it anywhere. Set the `PB_VIEWER_URL` environment variable to override it.

```sh
git clone https://github.com/<you>/paste.git
cd paste
ln -s "$PWD/bin/pb" ~/.local/bin/pb
gh auth login
ln -s "$PWD/skill" ~/.claude/skills/to-html
```

Keep the clone in place: `~/.local/bin/pb` is a symlink resolved back into the repo, and `bin/bundle` must sit next to it.
