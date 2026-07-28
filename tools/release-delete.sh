#!/usr/bin/env bash
#
# release-delete.sh - Remove a draft release and its tags.
#
# SPDX-FileCopyrightText: Oleg Shparber, et al. <https://zealdocs.org>
# SPDX-License-Identifier: MIT
#
# Deletes the GitHub release, the remote tag, and the local tag for a version,
# so `just release-push` can be run again. Refuses to touch a published release
# on the canonical repo; published rehearsal releases on a fork are fair game,
# since CI publishes them on success. Missing pieces are reported and skipped,
# so the script can clean up after a partial run.
#
# Usage: tools/release-delete.sh <version> [remote]
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

# Releases here are never disposable, unlike rehearsal releases on a fork.
CANONICAL_REPO="zealdocs/zeal"

repo=$(git remote get-url "$REMOTE" | sed -E 's|^.*github\.com[:/]||; s|\.git$||')

# Absent releases leave `draft` empty, which is treated as nothing to delete.
draft=$(gh release view "$TAG" --repo "$repo" --json isDraft --jq .isDraft 2>/dev/null || true)

if [ "$draft" = "false" ] && [ "$repo" = "$CANONICAL_REPO" ]; then
    echo "${TAG} is published on ${repo}; refusing to delete." >&2
    exit 1
fi

if [ -n "$draft" ]; then
    if [ "$draft" = "false" ]; then
        echo "Note: ${TAG} on ${repo} is published, not a draft."
    fi
    gh release delete "$TAG" --repo "$repo" --yes
    echo "Deleted release ${TAG} on ${repo}."
else
    echo "No release ${TAG} on ${repo}."
fi

if git ls-remote --exit-code --tags "$REMOTE" "$TAG" > /dev/null 2>&1; then
    git push "$REMOTE" ":refs/tags/${TAG}"
    echo "Deleted ${TAG} on ${REMOTE}."
else
    echo "No ${TAG} on ${REMOTE}."
fi

if git rev-parse -q --verify "refs/tags/${TAG}" > /dev/null; then
    git tag -d "$TAG"
else
    echo "No local ${TAG}."
fi
