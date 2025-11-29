#!/usr/bin/env bash

PIGOS_CLONE_PATH=$(git rev-parse --show-toplevel)
PIGOS_BRANCH=$(git rev-parse --abbrev-ref HEAD)
PIGOS_REMOTE=$(git config --get remote.origin.url)
PIGOS_VERSION=$(git describe --tags --always)
PIGOS_COMMIT_HASH=$(git rev-parse HEAD)
PIGOS_VERSION_COMMIT_MSG=$(git log -1 --pretty=%B)
PIGOS_VERSION_LAST_CHECKED=$(date +%Y-%m-%d\ %H:%M%S\ %z)

generate_release_notes() {
  local latest_tag
  local commits

  latest_tag=$(git describe --tags --abbrev=0 2>/dev/null)

  if [[ -z "$latest_tag" ]]; then
    echo "No release tags found"
    return
  fi

  echo "=== Changes since $latest_tag ==="

  commits=$(git log --oneline --pretty=format:"• %s" "$latest_tag"..HEAD 2>/dev/null)

  if [[ -z "$commits" ]]; then
    echo "No commits since last release"
    return
  fi

  echo "$commits"
}

# PIGOS_RELEASE_NOTES=$(generate_release_notes)

echo "PigOS $PIGOS_VERSION built from branch $PIGOS_BRANCH at commit ${PIGOS_COMMIT_HASH:0:12} ($PIGOS_VERSION_COMMIT_MSG)"
echo "Date: $PIGOS_VERSION_LAST_CHECKED"
echo "Repository: $PIGOS_CLONE_PATH"
echo "Remote: $PIGOS_REMOTE"
echo ""

if [[ "$1" == "--cache" ]]; then
  state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/pigos"
  mkdir -p "$state_dir"
  version_file="$state_dir/version"

  cat >"$version_file" <<EOL
PIGOS_CLONE_PATH='$PIGOS_CLONE_PATH'
PIGOS_BRANCH='$PIGOS_BRANCH'
PIGOS_REMOTE='$PIGOS_REMOTE'
PIGOS_VERSION='$PIGOS_VERSION'
PIGOS_VERSION_LAST_CHECKED='$PIGOS_VERSION_LAST_CHECKED'
PIGOS_VERSION_COMMIT_MSG='$PIGOS_VERSION_COMMIT_MSG'
PIGOS_COMMIT_HASH='$PIGOS_COMMIT_HASH'
EOL
# PIGOS_RELEASE_NOTES='$PIGOS_RELEASE_NOTES'

  echo -e "Version cache output to $version_file\n"

elif [[ "$1" == "--release-notes" ]]; then
  echo "$PIGOS_RELEASE_NOTES"

fi
