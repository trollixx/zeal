#!/usr/bin/env bash
#
# release-push.sh - Commit, tag, and push a prepared release.
#
# SPDX-FileCopyrightText: Oleg Shparber, et al. <https://zealdocs.org>
# SPDX-License-Identifier: MIT
#
# Commits the appdata and version bump left by release-prepare.sh, pushes the
# branch, creates the draft GitHub release from the generated notes, then tags
# and pushes the tag, which starts the build CI. The commit and tag steps are
# skipped if already done, so the same version can go to a fork first and then
# be promoted to upstream.
#
# Usage: tools/release-push.sh <version> [remote]
#

set -euo pipefail
trap 'echo "ERROR: failed at line ${LINENO}: ${BASH_COMMAND}" >&2' ERR

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage: $0 <version> [remote]" >&2
    exit 2
fi

VERSION="$1"
REMOTE="${2:-origin}"
TAG="v${VERSION}"

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid version: '${VERSION}'. Expected major.minor.patch (e.g. 0.9.0)." >&2
    exit 2
fi

repo=$(git remote get-url "$REMOTE" | sed -E 's|^.*github\.com[:/]||; s|\.git$||')

git add assets/freedesktop/org.zealdocs.zeal.appdata.xml.in CMakeLists.txt
if git diff --staged --quiet; then
    echo "Nothing to commit; ${TAG} content is already committed."
else
    git commit -m "chore: release ${TAG}"
fi

# Annotated: `git describe` without `--tags` ignores lightweight tags, and the
# AUR zeal-git package derives its version that way.
if git rev-parse -q --verify "refs/tags/${TAG}" > /dev/null; then
    echo "Tag ${TAG} already exists; reusing it."
else
    git tag -a "$TAG" -m "$TAG"
fi

git push "$REMOTE" HEAD

# Created before the tag is pushed, so the draft is in place when CI starts.
gh release create "$TAG" --draft --notes-file build/release-notes.md --repo "$repo"

git push "$REMOTE" "$TAG"

echo "Pushed ${TAG} to ${repo}. CI will build, upload, and publish."
