# NOTICE

This repository packages and redistributes upstream software published by the
[difftastic](https://difftastic.wilfred.me.uk/) project. The Apache-2.0 license
in [`LICENSE`](LICENSE) covers the OCX pipeline files authored here. It does
**not** cover any upstream-derived asset — each package's redistributed bytes
carry their own license, recorded below.

Each package's logo is reproduced for catalog identification only, under
nominative fair use. The marks remain the property of their respective owners
and no endorsement is implied.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `difftastic` | `ghcr.io/ocx-contrib/difftastic/difftastic` | `MIT` |

---

## `difftastic`

Upstream: <https://github.com/Wilfred/difftastic>
Published to `ghcr.io/ocx-contrib/difftastic/difftastic`.

| Component | SPDX | Holder |
|---|---|---|
| difftastic (`difft`) | **MIT** | Wilfred Hughes |

The MIT License grants redistribution of the compiled binary in source and
binary forms, on the single condition that the copyright notice and permission
notice accompany it. That notice ships inside the mirrored archives' upstream
`LICENSE` file — republished unmodified — and is reproduced by reference here.

The published binaries statically link third-party Rust crates and vendored
tree-sitter grammars under their own permissive licenses; the crate set is
enumerated in the `Cargo.lock` of the corresponding upstream source tag, and
the vendored grammars in `vendored_parsers/` of the same tree.

No modifications are made to any upstream artifact in this repository; they are
republished byte-for-byte inside an OCX bundle.
