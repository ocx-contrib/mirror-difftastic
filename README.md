# mirror-difftastic

OCX mirror for [difftastic](https://difftastic.wilfred.me.uk/), a structural
diff that understands syntax. One repository, one spec directory per package.

| Package | Spec | Publishes to | Announced as | Upstream SPDX |
|---|---|---|---|---|
| [difftastic](https://github.com/Wilfred/difftastic) | [`difftastic/mirror.yml`](difftastic/mirror.yml) | `ghcr.io/ocx-contrib/difftastic/difftastic` | [`ocx.sh/difftastic/difftastic`](https://index.ocx.sh/difftastic/difftastic) | `MIT` |

Each upstream release is discovered, re-bundled, smoke-tested per
`(version, platform)` and only then pushed with cascade tags, after which the
result is announced into the OCX index.

`Wilfred` is a personal handle rather than a vendor, so the tool names itself:
the package is `difftastic/difftastic`. **The executable it ships is `difft`.**

## Layout

```
mirror-base.yml         repo-wide policy every spec inherits via `extends:`
difftastic/
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
└── tests/smoke.star    Starlark smoke test
```

`LICENSE` and `NOTICE.md` are shared at the root. Logos are **not** — each
package carries its own, because a repo-root `logo.*` sits in no workflow's
`paths:` filter, so replacing it would publish nothing until some unrelated
edit happened to fire.

⚠️ `extends:` is a **shallow** merge of top-level keys. A spec that restates
`platforms:` to change one runner drops every `containers:` entry with it, and
nothing reds — the legs simply stop existing, and every `os.features` claim
goes back to being asserted rather than verified. This repo sidesteps the trap
structurally: it is single-package, `platforms:` lives only in
`mirror-base.yml`, and `difftastic/mirror.yml` never restates it.

## Platforms

difftastic publishes six platform entries: both Linux arches, both macOS arches
and both Windows arches. **The two Linux keys are asymmetric, and that is
measured rather than assumed:**

| Key | Asset carried | Why |
|---|---|---|
| `linux/amd64` — **bare** | `difft-x86_64-unknown-linux-musl.tar.gz` | static-pie: `readelf -l` reports **0** `INTERP` segments and `readelf -d` **no** `NEEDED`. It requires nothing of the host |
| `linux/arm64+libc.glibc` | `difft-aarch64-unknown-linux-gnu.tar.gz` | upstream ships **no** aarch64 musl asset. The gnu build carries `PT_INTERP /lib/ld-linux-aarch64.so.1` and `NEEDED libc.so.6` (max symbol `GLIBC_2.18`) |

`os.features` states what an artifact requires *of the host*, so a musl target
*triple* is not a musl *requirement*: tagging the static amd64 build
`+libc.musl` would be a false claim that hid it from every glibc host it in
fact runs on. The `alpine:3.20` container leg on the bare key is what turns its
universality claim into evidence; the `+libc.glibc` key gets **no** alpine leg,
because the binary genuinely cannot load under musl and the renderer rejects
that leg at spec load (exit 65). The measurements themselves are recorded above
the `assets:` block in `difftastic/mirror.yml`.

The amd64 `-gnu` build exists and is deliberately not carried. Publishing it
beside the static one under `+libc.glibc` is legal and resolves correctly by
specificity scoring, but it only buys something where musl's libc changes
behaviour a user can reach — canonically DNS/NSS resolution. difftastic diffs
local files and opens no socket.

## Asset names carry no version

`difft-x86_64-apple-darwin.tar.gz` is the *same filename* in 0.67.0, 0.68.0 and
0.69.0 — the version exists only in the tag and the download URL path. The
`assets:` patterns are therefore **exact anchored literals**, not the
`difft-.*-<triple>` shape a version-bearing upstream would take. Digest
verification is unaffected: `verify.github_asset_digest` reads the digest from
that release's own asset id, and the identical filename hashes differently per
release.

Upstream ships exactly seven assets per release, no sidecars at all — no
`SHA256SUMS`, no signatures, no `.deb`/`.rpm`/`.msi` — and no
armv7/i686/riscv64/s390x builds, so nothing is dropped for want of an OCX
platform key. Six of the seven are carried; the seventh is the amd64 `-gnu`
build discussed above.

## The binaries claim

Every archive — tarball and zip alike — is **flat and holds exactly one
entry**: `difft` (`difft.exe` in the zips), mode 0755, with no wrapper
directory, no docs and no completions. So `strip_components: 0` serves every
platform, the binary lands at the content root, and the bundle's only PATH
entry is a bare `${installPath}`.

`bin_scan` only looks *below* an `${installPath}/<dir>` entry, so with nothing
to inspect it would pass green whatever the archive contained, and `auto` /
`verify` are rejected at spec load with exit 65. `difftastic/mirror.yml`
therefore sets `bin_scan: "off"` and `difftastic/metadata.json` hand-lists
`["difft"]` — the blessed shape for this layout, and exactly what the error
message directs.

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror-base.yml`, `difftastic/mirror.yml` | hand | yes — see below |
| `difftastic/{metadata.json,CATALOG.md,logo.*}` | hand | — |
| `difftastic/tests/smoke.star` | hand | — |
| `.github/workflows/*.yml` | **generated — never hand-edit** | re-run when a spec changes |

```bash
ocx-mirror package pipeline generate ci --spec difftastic/mirror.yml
```

**Name every spec.** `--spec` *appends* rather than replaces, so a command
naming a subset silently stops rendering the rest while staying green — and the
drift guard reds on a generated workflow the current spec set no longer
produces.

`verify-generated.yml` exits 65 on drift. If a generated workflow is wrong, the
spec or the renderer template is wrong — fix it there and regenerate.

Run `direnv allow` once to put the pinned toolchain on `PATH`, and invoke
`ocx-mirror` directly — never `ocx run -- ocx-mirror`, which pins
`OCX_BINARY_PIN` to the bootstrap `ocx` and false-reds the nested push.

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_ANNOUNCE_TOKEN` | opens the index pull request from the `ocx-contrib/index` fork |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL. GHCR pushes use the
run's own `GITHUB_TOKEN` — no registry secret needed.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of scope; each
package's redistribution license is recorded in [`NOTICE.md`](NOTICE.md).
