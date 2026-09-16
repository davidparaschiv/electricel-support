#!/usr/bin/env bash
set -euo pipefail

SOURCE_BRANCH="${SOURCE_BRANCH:-master}"
PUBLISH_BRANCH="gh-pages"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPOSITORY_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
REMOTE_URL="$(git -C "$REPOSITORY_ROOT" remote get-url origin)"

if git -C "$REPOSITORY_ROOT" show-ref --verify --quiet "refs/heads/$SOURCE_BRANCH"; then
  SOURCE_REF="$SOURCE_BRANCH"
elif git -C "$REPOSITORY_ROOT" show-ref --verify --quiet "refs/remotes/origin/$SOURCE_BRANCH"; then
  SOURCE_REF="origin/$SOURCE_BRANCH"
else
  echo "Nu există branch-ul $SOURCE_BRANCH local sau pe origin."
  exit 1
fi

if ! git -C "$REPOSITORY_ROOT" cat-file -e "$SOURCE_REF:site/index.html"; then
  echo "Folderul site trebuie să fie comis în branch-ul $SOURCE_BRANCH înainte de deploy."
  exit 1
fi

PUBLISH_DIR="$(mktemp -d "${TMPDIR:-/tmp}/electricel-pages.XXXXXX")"
cleanup() {
  git -C "$REPOSITORY_ROOT" worktree remove --force "$PUBLISH_DIR" >/dev/null 2>&1 || true
}
trap cleanup EXIT

REMOTE_COMMIT=""
if git -C "$REPOSITORY_ROOT" ls-remote --exit-code --heads origin "$PUBLISH_BRANCH" >/dev/null 2>&1; then
  git -C "$REPOSITORY_ROOT" fetch --quiet origin "$PUBLISH_BRANCH"
  REMOTE_COMMIT="$(git -C "$REPOSITORY_ROOT" rev-parse FETCH_HEAD)"
  git -C "$REPOSITORY_ROOT" worktree add --quiet --detach "$PUBLISH_DIR" "$REMOTE_COMMIT"
else
  git -C "$REPOSITORY_ROOT" worktree add --quiet --detach "$PUBLISH_DIR" "$SOURCE_REF"
fi

git -C "$PUBLISH_DIR" checkout --quiet --orphan electricel-pages-publish
git -C "$PUBLISH_DIR" rm -rf --quiet .
git -C "$REPOSITORY_ROOT" archive "$SOURCE_REF:site" | tar -x -C "$PUBLISH_DIR"
touch "$PUBLISH_DIR/.nojekyll"
git -C "$PUBLISH_DIR" add --all
git -C "$PUBLISH_DIR" commit --quiet -m "Deploy Suport Electricel"

if [[ -n "$REMOTE_COMMIT" ]]; then
  git -C "$PUBLISH_DIR" push origin "HEAD:refs/heads/$PUBLISH_BRANCH" \
    "--force-with-lease=refs/heads/$PUBLISH_BRANCH:$REMOTE_COMMIT"
else
  git -C "$PUBLISH_DIR" push origin "HEAD:refs/heads/$PUBLISH_BRANCH"
fi

REPOSITORY_SLUG="$(printf '%s' "$REMOTE_URL" | sed -E 's#^git@github.com:##; s#^https://github.com/##; s#\.git$##')"
if command -v gh >/dev/null 2>&1 && [[ "$REPOSITORY_SLUG" == */* ]]; then
  if gh api "repos/$REPOSITORY_SLUG/pages" >/dev/null 2>&1; then
    gh api --method PUT "repos/$REPOSITORY_SLUG/pages" \
      -F 'source[branch]=gh-pages' -F 'source[path]=/' >/dev/null
  else
    gh api --method POST "repos/$REPOSITORY_SLUG/pages" \
      -F 'source[branch]=gh-pages' -F 'source[path]=/' >/dev/null
  fi
  echo "GitHub Pages este configurat din branch-ul gh-pages."
else
  echo "Deploy finalizat. Configurează o singură dată GitHub Pages cu branch-ul gh-pages și folderul / (root)."
fi

echo "Suport Electricel a fost publicat din $SOURCE_BRANCH în $PUBLISH_BRANCH."
