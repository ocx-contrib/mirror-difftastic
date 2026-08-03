# difftastic/tests/smoke.star — stable across upstream releases.
# difftastic is a STRUCTURAL diff: it parses both sides with tree-sitter and
# compares syntax trees, so a change that only moves whitespace is not a
# change. That property is the whole contract, and it is what these assertions
# check — never help/version prose.
#
# Two traps this file is written around, both measured on 0.69.0:
#
#   1. Plain `difft` EXITS 0 whether or not the files differ. The exit code
#      only becomes a signal under the explicit `--exit-code` flag, which is
#      documented as "set the exit code to 1 if there are syntactic changes".
#      So the exit code is asserted only where that flag is passed.
#   2. Colored output carries one SGR sequence PER TOKEN — the bytes are
#      `ESC[2m1 ESC[0mESC[1mfunction ESC[0m greet() {` — so a multi-word plain
#      substring is NEVER contiguous there. The color path is proven by
#      comparing the two renders instead.
#
# The binary is `difft`, not `difftastic`: the package is named for the
# project, the executable for the command you type.

DIFFT = "difft.exe" if ocx.target_platform.os == ocx.os.Windows else "difft"

# Tier 1 + 2: liveness on the composed PATH + version SHAPE (not the vendor
# banner, not the exact version — the digits are the contract).
r_version = ocx.run(DIFFT, "--version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# Hermetic inputs. `b.js` is `a.js` REFORMATTED — same syntax tree, different
# bytes. `c.js` changes a literal — different syntax tree.
ocx.write_file("a.js", "function greet() {\n  return 1;\n}\n")
ocx.write_file("b.js", "function greet() { return 1; }\n")
ocx.write_file("c.js", "function greet() {\n  return 2;\n}\n")

# Tier 3a: THE structural contract, and the assertion that would red against a
# truncated or wrong-flavour archive. Every tree-sitter grammar is compiled
# INTO the ~125 MB executable; if the JavaScript parser failed to ship, difft
# falls back to byte comparison for an undetected language ("sets the exit code
# if there are any byte changes") and this reformat-only pair — which IS byte
# different — would exit 1 instead of 0.
r_same = ocx.run(DIFFT, "--color", "never", "--width", "80", "--exit-code", "a.js", "b.js")
expect.eq(r_same.exit_code, 0)

# Tier 3b: the other direction — a real syntactic change must be detected, so
# a green run needs BOTH halves. The rendered diff echoes the identifier from
# our own hermetic input, which proves difft actually read and rendered the
# files rather than bailing out early.
r_diff = ocx.run(DIFFT, "--color", "never", "--width", "80", "--exit-code", "a.js", "c.js")
expect.eq(r_diff.exit_code, 1)
expect.contains(r_diff.stdout, "greet")

# Tier 3c: syntax highlighting actually ran. The same pair is rendered twice —
# once uncolored, once forced colored — and the two are compared. Asserting the
# renders DIFFER is the theme-independent proof: with no color support the two
# would be byte-identical. Do NOT assert a multi-word substring against the
# colored side (see trap 2 in the header).
r_plain = ocx.run(DIFFT, "--color", "never", "--width", "80", "a.js", "c.js")
expect.ok(r_plain)
r_color = ocx.run(DIFFT, "--color", "always", "--width", "80", "a.js", "c.js")
expect.ok(r_color)
expect.matches(r_color.stdout, r"\x1b\[")
expect.ne(r_color.stdout, r_plain.stdout)

# No Tier 4: metadata.json declares PATH only (proven by Tier 1 liveness).
