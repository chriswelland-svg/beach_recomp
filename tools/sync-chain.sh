#!/usr/bin/env bash
# sync-chain.sh -- push the three-repo pointer chain in dependency order.
#
# Why this exists
# ---------------
# Each repo in the stack pins the one below it with a gitlink:
#
#     beach_recomp            pins  lib/ModernGekko            (gitlink)
#     ModernGekko             pins  vendor/dolphin             (gitlink)
#     RecompCore (vendor)     -- leaf
#     DolRecomp (root copy)   -- leaf, pinned directly by beach_recomp
#
# So a change at the bottom has to be pushed bottom-up, and the pointer bumped
# in the repo above at each step. Doing that by hand is three repos' worth of
# `git add <submodule> && git commit && git push` in the right order -- get the
# order wrong and CI checks out a commit no remote has yet and fails.
#
# Remote policy (enforced, not advisory)
# --------------------------------------
# In the submodule repos `origin` is ExpansionPak -- upstream. We never push
# there; the forks are the `fork` remote. In beach_recomp itself `origin` is
# kobayashi90/beach_recomp and `upstream` is ExpansionPak/ModernGekko-Template,
# so beach_recomp pushes to `origin`. Every push target is asserted to contain
# "kobayashi90" before it is used, so a mis-named remote cannot leak a push
# upstream.
#
# Uncommitted work
# ----------------
# There is standing uncommitted work that must survive this script untouched:
# the DolRecomp WIP (src/app/pipeline.c, c_cfg.c, emitter.c/.h), the vendored
# SDL WIP, and an untracked .directory. The script stages *only* gitlink paths
# and refuses to run if it finds dirt outside the allowlist below.
#
# Usage
# -----
#   tools/sync-chain.sh            dry run: report state, change nothing
#   tools/sync-chain.sh --push     execute the chain, pushing at each level
#   tools/sync-chain.sh -m "msg"   use "msg" for the generated pointer-bump
#                                  commit messages instead of the default

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDOR="$ROOT/lib/ModernGekko/vendor/dolphin"
MODERN="$ROOT/lib/ModernGekko"
DOLROOT="$ROOT/lib/DolRecomp"

DO_PUSH=0
COMMIT_MSG=""

while [ $# -gt 0 ]; do
    case "$1" in
        --push) DO_PUSH=1; shift ;;
        -m) COMMIT_MSG="${2:?-m needs a message}"; shift 2 ;;
        -h|--help) sed -n '2,40p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown argument: $1 (try --help)" >&2; exit 2 ;;
    esac
done

if [ "$DO_PUSH" = 1 ]; then
    echo "==> executing chain (pushes enabled)"
else
    echo "==> dry run -- no commits, no pushes (add --push to execute)"
fi
echo

# Dirt outside this list aborts the run: either someone's work in progress that
# this script has no business committing, or a surprise we want to look at
# first. Matched as substrings against `git status --porcelain` lines, so the
# staged/unstaged column forms and the submodule flag (`m`) are all covered.
ALLOW='src/(app/pipeline\.c|backend/c_cfg\.c|backend/emitter\.c|backend/emitter\.h)$'
ALLOW+='|vendor/dolphin$'
ALLOW+='|DolRecomp$'
ALLOW+='|Externals/SDL/SDL$'
ALLOW+='|lib/ModernGekko$'
ALLOW+='|\.directory$'
ALLOW+='|^UU |^AA |^U[AD] |^D[AD] '              # merge conflict markers: report, don't hide

fail=0

# $1 = repo dir, $2 = human name
report_dirt() {
    local dir="$1" name="$2" dirty
    dirty="$(git -C "$dir" status --porcelain || true)"
    [ -z "$dirty" ] && return 0
    local stray
    stray="$(printf '%s\n' "$dirty" | grep -Ev "$ALLOW" || true)"
    if [ -n "$stray" ]; then
        echo "  !! $name has files outside the known-WIP allowlist:" >&2
        printf '%s\n' "$stray" | sed 's/^/       /' >&2
        fail=1
    else
        echo "  .. $name has known uncommitted WIP (left alone)"
    fi
}

# $1 = repo dir, $2 = push remote, $3 = branch
push_branch() {
    local dir="$1" remote="$2" branch="$3"
    local url
    url="$(git -C "$dir" remote get-url --push "$remote" 2>/dev/null || echo '')"
    if [ -z "$url" ]; then
        echo "  !! $dir has no '$remote' push remote" >&2
        fail=1
        return 0
    fi
    case "$url" in
        *kobayashi90*) : ;;
        *)
            echo "  !! refusing to push: '$remote' in $dir points at" >&2
            echo "       $url" >&2
            echo "     (only kobayashi90/* push targets are allowed)" >&2
            fail=1
            return 0 ;;
    esac
    if [ "$DO_PUSH" = 1 ]; then
        echo "  -> pushing $remote/$branch"
        git -C "$dir" push "$remote" "$branch"
    else
        echo "  == would push $remote/$branch ($url)"
    fi
}

# Commit a gitlink change for exactly one path, if it differs from HEAD.
# $1 = repo dir, $2 = path inside repo, $3 = default message
bump_gitlink() {
    local dir="$1" path="$2" msg="$3"
    git -C "$dir" add -- "$path"
    if git -C "$dir" diff --cached --quiet -- "$path"; then
        echo "  == $path already at the recorded commit"
        return 0
    fi
    local sha
    sha="$(git -C "$dir" rev-parse --short HEAD:"$path" 2>/dev/null || echo 'n/a')"
    if [ "$DO_PUSH" = 1 ]; then
        git -C "$dir" commit --no-verify -m "${COMMIT_MSG:-$msg}" -- "$path"
        echo "  ++ bumped $path -> $(git -C "$dir" rev-parse --short HEAD:"$path")"
    else
        echo "  ++ would commit $path (now $sha on HEAD, staged value differs)"
    fi
}

echo "--- level 1: RecompCore (vendor/dolphin) -- leaf"
report_dirt "$VENDOR" "vendor/dolphin"
git -C "$VENDOR" fetch fork --quiet 2>/dev/null || true
VBR="$(git -C "$VENDOR" symbolic-ref --short HEAD 2>/dev/null || echo '')"
if [ -z "$VBR" ]; then
    echo "  !! vendor/dolphin is on a detached HEAD; check it out first" >&2
    fail=1
else
    unpushed="$(git -C "$VENDOR" rev-list --count "fork/$VBR..$VBR" 2>/dev/null || echo '?')"
    echo "  branch $VBR, $unpushed commit(s) not on fork/$VBR"
    if [ "$unpushed" = "?" ]; then
        echo "  ?? no fork/$VBR to compare against yet" >&2
        push_branch "$VENDOR" fork "$VBR"
    elif [ "$unpushed" -gt 0 ]; then
        push_branch "$VENDOR" fork "$VBR"
    else
        echo "  == fork already up to date"
    fi
fi

echo
echo "--- level 2: ModernGekko -- pins vendor/dolphin"
report_dirt "$MODERN" "ModernGekko"
bump_gitlink "$MODERN" vendor/dolphin "Bump vendor: pointer update"
git -C "$MODERN" fetch fork --quiet 2>/dev/null || true
MUNPUSHED="$(git -C "$MODERN" rev-list --count fork/master..master 2>/dev/null || echo '?')"
echo "  master, $MUNPUSHED commit(s) not on fork/master"
if [ "$MUNPUSHED" != "0" ] && [ "$MUNPUSHED" != "?" ]; then
    push_branch "$MODERN" fork master
elif [ "$MUNPUSHED" = "?" ]; then
    echo "  ?? could not compare against fork/master" >&2
else
    echo "  == fork already up to date"
fi

echo
echo "--- level 3: beach_recomp -- pins lib/ModernGekko (+ lib/DolRecomp)"
report_dirt "$ROOT" "beach_recomp"
report_dirt "$DOLROOT" "lib/DolRecomp (WIP -- never staged, never pushed)"
bump_gitlink "$ROOT" lib/ModernGekko "Bump ModernGekko: pointer update"

# lib/DolRecomp carries standing WIP and has no fork remote (origin is
# ExpansionPak). Never stage it, never push it -- only report that its recorded
# pin and its checkout have parted company, which is a decision for the owner.
DOL_PIN="$(git -C "$ROOT" rev-parse --short HEAD:lib/DolRecomp 2>/dev/null || echo '?')"
DOL_NOW="$(git -C "$DOLROOT" rev-parse --short HEAD 2>/dev/null || echo '?')"
if [ "$DOL_PIN" != "$DOL_NOW" ]; then
    echo "  ?? lib/DolRecomp pin ($DOL_PIN) != checkout ($DOL_NOW)"
    echo "     not staged: this repo has uncommitted WIP and no fork remote."
    echo "     syncing it is a separate, deliberate decision."
else
    echo "  == lib/DolRecomp pin matches its checkout ($DOL_PIN)"
fi

git -C "$ROOT" fetch origin --quiet 2>/dev/null || true
BUNPUSHED="$(git -C "$ROOT" rev-list --count origin/main..main 2>/dev/null || echo '?')"
BEHIND="$(git -C "$ROOT" rev-list --count main..origin/main 2>/dev/null || echo '?')"
echo "  main: $BUNPUSHED ahead, $BEHIND behind origin/main"
if [ "$BEHIND" != "0" ]; then
    echo "  !! origin/main has moved; rebase/merge before pushing" >&2
    fail=1
fi
if [ "$BUNPUSHED" != "0" ] && [ "$BUNPUSHED" != "?" ]; then
    push_branch "$ROOT" origin main
else
    echo "  == origin already up to date"
fi

echo
if [ "$fail" = 1 ]; then
    echo "RESULT: blocked -- see the '!!' lines above."
    exit 1
fi
if [ "$DO_PUSH" = 1 ]; then
    echo "RESULT: chain pushed. Watch CI:"
    echo "  gh run list -R kobayashi90/beach_recomp --limit 5"
else
    echo "RESULT: dry run clean. Re-run with --push to execute."
fi
