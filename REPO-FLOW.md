# Repo flow — the three-repo chain

How this stack is wired, how to push it, and what is deliberately *not*
resolved yet. Read this before touching a submodule pointer.

## The chain

Each repo pins the one below it with a gitlink, so a change at the bottom has
to travel upward in order:

```
kobayashi90/beach_recomp          pins  lib/ModernGekko
kobayashi90/ModernGekko           pins  vendor/dolphin
kobayashi90/RecompCore            -- leaf (the vendor/dolphin tree)
lib/DolRecomp                     -- leaf, pinned directly by beach_recomp
```

Get the order wrong and CI checks out a commit no remote has yet and fails.

## Remotes and push policy

| Repo | `origin` | `fork` / `upstream` | Push here? |
|---|---|---|---|
| beach_recomp | **kobayashi90/beach_recomp** | `upstream` = ExpansionPak/ModernGekko-Template | yes (`origin`) |
| ModernGekko | ExpansionPak/ModernGekko | `fork` = **kobayashi90/ModernGekko** | `fork` only |
| vendor/dolphin (RecompCore) | ExpansionPak/RecompCore | `fork` = **kobayashi90/RecompCore** | `fork` only |
| lib/DolRecomp | ExpansionPak/DolRecomp | *(no fork remote)* | never |

In the submodule repos `origin` is upstream, not us — pushing `origin` there
would write to ExpansionPak. `tools/sync-chain.sh` asserts every push target
contains `kobayashi90` before it pushes, so a mis-named remote cannot leak a
push upstream.

`gh` also defaults to `ExpansionPak/ModernGekko-Template`. `gh repo set-default`
has now been run inside all three repos, so bare `gh` resolves correctly from
each directory; pass `-R kobayashi90/beach_recomp` when running it from
anywhere else.

## Pushing

```
tools/sync-chain.sh          # dry run: report state, change nothing
tools/sync-chain.sh --push   # execute the chain, pushing at each level
```

It bumps each gitlink, commits the bump, and pushes bottom-up. It refuses to
run if `git status` shows dirt outside the known-WIP allowlist, so standing
uncommitted work cannot be swept into a pointer-bump commit:

* `lib/DolRecomp` — `src/app/pipeline.c`, `src/backend/c_cfg.c`,
  `src/backend/emitter.c`, `src/backend/emitter.h`
* `lib/ModernGekko/vendor/dolphin/Externals/SDL/SDL`
* the untracked `.directory`

## CI

`.github/workflows/build.yml` runs on push, PR, dispatch and release.

* **Windows now runs on push too** (it was gated to `release` +
  `workflow_dispatch && inputs.windows`, which meant every push needed a
  second manual `workflow_dispatch -f windows=true` to know whether Windows
  still built). The `windows` dispatch input stays as an escape hatch.
* Submodules are checked out from **pinned gitlinks** (`git submodule update
  --init --recursive --force`) with no `--remote`, so the `branch =` field in
  `.gitmodules` never affects CI — it only matters for a manual
  `git submodule update --remote`.

The `.gitmodules` branch for `vendor/dolphin` (in `lib/ModernGekko`) was
`moderngekko-vendor`, which on our fork is ExpansionPak's line — a manual
`--remote` update would have silently reverted the Beach Spikers work back to
upstream state. It now reads `branch = beach-spikers-x11-mouse`, matching the
branch that is actually pinned, and `fork/moderngekko-vendor` has been
fast-forwarded to the same tip so neither name can regress the work.

## Shallow clones: assume nothing until you check

`lib/ModernGekko` and `lib/DolRecomp` were both shallow clones (ModernGekko had
two boundary roots; `.gitmodules` sets `shallow = true`). Every conclusion
drawn from a shallow clone here was wrong, and wrong in the alarming
direction:

* ModernGekko looked like upstream had **rewritten history** — "unrelated
  histories, the whole tree being added". It had not; the parents were simply
  missing. `git fetch --unshallow` restored a real merge-base.
* The DolRecomp pin `1bec355` looked like a **local-only commit that no remote
  served** — a landmine, since the pin would stop resolving for anyone else.
  It is upstream history all along (`merge-base --is-ancestor` = true, 0 ahead
  / 21 behind). That is also the answer to how CI's submodule checkout
  succeeded: the pin was always fetchable from ExpansionPak/DolRecomp.

Check for shallowness first: `test -f "$(git rev-parse --git-dir)/shallow"`.

## Open decisions

### 1. Two DolRecomp copies — `make recompile` uses the wrong one

There are two independent DolRecomp checkouts, and they are not equivalent:

| | `lib/DolRecomp` | `lib/ModernGekko/vendor/dolphin/DolRecomp` |
|---|---|---|
| Used by | `make dolrecomp` → `extract` / `--setup` | `add_subdirectory` → the `dolrecomp` that `moderngekko-port` runs |
| Carries the perf WIP | **yes** | no (clean) |
| Chains calls | **yes** | **no** — zero callers of `emit_set_chunk_table` |

`moderngekko_port.cpp:720` resolves the recompiler as
`SiblingExecutable(argv0, "dolrecomp")`, and CMake fills that path from the
*vendored* copy (`moderngekko-port-recompiler` copies `$<TARGET_FILE:dolrecomp>`
beside the port on every build). `DOLRECOMP_CHAIN_CALLS` is also absent from
`DolRecompCodegenIdentity()`'s env list, so the port neither sets it nor folds
it into the cache key.

Evidence:

* `lib/ModernGekko/build/dolrecomp` = `5e8976bd…`, built Nov 2 — **no**
  `DOLRECOMP_CHAIN_CALLS`, `DOLRECOMP_LAZY_PC` or `DOLRECOMP_FHELPER_INLINE`
  strings. It structurally cannot chain.
* `lib/DolRecomp/build/dolrecomp` = `14a3a539…`, built Nov 8 13:35 — has all
  three.
* The shipped generated sources are dated **Nov 8 13:36**, one minute after
  the *root* binary was rebuilt — i.e. produced by the direct invocation
  documented in `PERFORMANCE.md`, not by `make recompile`.
* All three `build/modules/*/manifest.txt` claim
  `dolrecomp_binary_sha256=5e8976bd…` (the sibling), and are dated **Nov 12**:
  `publish_module()` re-ran on a cache hit and re-stamped a binary that did
  not build those sources. **The manifests' provenance is wrong.**

So today's chained, measured modules exist because generation was done by
hand. A cache miss or clean rebuild would run the vendored binary and silently
produce the unchained, slower build — the same class of failure
`PERFORMANCE.md` already caught once as the "NTSC-U recipe gap".

**Why it is not fixed yet:** any fix changes the recompiler's sha, which is in
the module cache key, which forces regeneration, which moves the object paths
that the `.gcda` profiles are keyed by — i.e. a **full PGO retrain**
(`tools/pgo.sh generate` ~26 min, `train`, `use` ~18 min) and a re-measure of
the 1.000 build. Two ways out, both needing a decision:

* make `make recompile` use `lib/DolRecomp` (copy `$(DOLRECOMP_BIN)` over
  `$(MODERNGEKKO_BUILD)/dolrecomp` after the CMake build), or
* move the perf WIP into `vendor/dolphin/DolRecomp` so the two copies stop
  diverging in the first place.

### 2. DolRecomp upstream sync

`lib/DolRecomp` is a pure fast-forward: **0 ahead / 21 behind** upstream
(`1bec355` → `02e27ac`), and the merge is clean against committed trees. Only
one of the four WIP files overlaps — upstream rewrote `src/app/pipeline.c`
(1637 insertions, 53 hunks) while her call-chaining WIP adds two hunks inside
`emit_code_sections_split` at old lines 1254 and 1415. `c_cfg.c`,
`emitter.c` and `emitter.h` are untouched upstream.

Worth knowing before deciding: upstream's `emitter.c` defines
`emit_set_chunk_table(starts, count)` but **never calls it** — their chaining
is dead code that always takes the safe return-to-chassis path. The WIP is what
activates it (and extends the signature with an `ends` bound so branch targets
landing in holes don't enter the wrong chunk). Rebased on top of upstream this
would need the WIP re-applied against the rewritten `pipeline.c`.

Left unmerged deliberately — touching that WIP is the owner's call.

**It is no longer only on this disk.** The 164-line WIP existed purely as
uncommitted working-tree changes — no commit, no remote, nothing but the
checkout. It is now also a real object on a local branch:

```
dolrecomp-wip-20261114 -> 389b358   (parent: 1bec355)
```

Created with `git stash create` + `git branch`, which snapshots the worktree
into a commit **without touching it**: the `git diff` sha256 was byte-identical
before and after (`7dfcbcaf…`), and `git status` still shows the same four
modified files with no stash entry added. `git diff 1bec355
dolrecomp-wip-20261114` reproduces the working diff exactly.

It is deliberately **not pushed**: `lib/DolRecomp`'s only remote is
`ExpansionPak/DolRecomp`, so publishing it would make uncommitted work public
without a decision. Once the rebase in decision 2 is made, the natural move is
to push it to a fork as a proper branch.

### 3. Four different DolRecomp revisions are in play

After the vendor merge, nothing pins the same DolRecomp twice:

| Where | Revision | Notes |
|---|---|---|
| `lib/DolRecomp` (root, the Makefile's `dolrecomp`) | `1bec355` **+ WIP** | `0 ahead / 21 behind` upstream; carries the perf work |
| `lib/DolRecomp` pin recorded in `beach_recomp` | `1bec355` | matches the checkout |
| `vendor/dolphin` **gitlink** (RecompCore's `DolRecomp`) | `71ce7f9` | upstream's PR #39 repin, merged in via `4582fda` |
| `vendor/dolphin/DolRecomp` **checkout** | `1bec355` | clean, and 21 behind its own gitlink |
| upstream `ExpansionPak/DolRecomp` `HEAD` | `02e27ac` | |

The `vendor/dolphin` gitlink/checkout mismatch is the trap: the tree shows
` M DolRecomp`, and the obvious fix — `git submodule update` — would move the
checkout to `71ce7f9`, rebuild the vendored recompiler, change its sha, and so
change the module cache key. That means regeneration, new object paths, and an
invalidated `.gcda` set — i.e. the same forced PGO retrain as decision 1.
**Do not "clean up" that dirty flag casually.** It is left as-is on purpose.

### 4. macOS

Report-only, untested. `PlatformMacos.mm` has zero
`NotifyHotkey`/`SetKeysym` calls; F-keys arrive via the native `NSMenu`.
