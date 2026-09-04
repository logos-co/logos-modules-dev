#!/usr/bin/env bash
# Add a repository to this catalog: registers it as a git submodule
# under submodules/, records every module found inside it in
# modules.json, and regenerates the per-module release workflows.
#
# Usage:
#   ./scripts/add-module.sh <git-url> [branch] [submodule-name]
#
# The branch matters here in a way it does not in a release catalog:
# sync-modules.yml polls `.gitmodules`'s `branch` for each submodule, so
# a submodule added without one is never advanced automatically. When
# omitted it is resolved from the remote's default branch.
#
# A repository may hold more than one module (logos-rln-modules holds
# three), so every metadata.json under it is registered separately.
# Review modules.json afterwards and drop anything that isn't a
# publishable module.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

URL="${1:-}"
if [ -z "${URL}" ]; then
  echo "usage: $0 <git-url> [branch] [submodule-name]" >&2
  exit 2
fi
BRANCH="${2:-}"
NAME="${3:-$(basename "${URL%.git}")}"
PATH_REL="submodules/${NAME}"

if [ -e "${PATH_REL}" ]; then
  echo "error: ${PATH_REL} already exists" >&2
  exit 1
fi

if [ -z "${BRANCH}" ]; then
  BRANCH="$(git ls-remote --symref "${URL}" HEAD \
            | awk '/^ref:/ {sub("refs/heads/","",$2); print $2; exit}')"
  [ -n "${BRANCH}" ] || { echo "error: could not resolve the default branch of ${URL}" >&2; exit 1; }
  echo "==> default branch: ${BRANCH}"
fi

echo "==> adding submodule ${NAME} (tracking ${BRANCH})"
git submodule add -b "${BRANCH}" "${URL}" "${PATH_REL}"

echo "==> registering modules found under ${PATH_REL}"
found=0
while read -r meta; do
  dir="$(dirname "${meta}")"
  mname="$(jq -r '.name // empty' "${meta}")"
  [ -n "${mname}" ] || { echo "    skip ${dir} (metadata.json has no name)"; continue; }
  if jq -e --arg n "${mname}" '.modules[] | select(.name == $n)' modules.json >/dev/null; then
    echo "    skip ${mname} (already in modules.json)"
    continue
  fi
  tmp="$(mktemp)"
  jq --arg n "${mname}" --arg p "${dir}" \
     '.modules += [{name: $n, path: $p}]' modules.json > "${tmp}"
  mv "${tmp}" modules.json
  echo "    + ${mname}  (${dir})"
  found=$((found + 1))
done < <(find "${PATH_REL}" -maxdepth 4 -name metadata.json -not -path '*/node_modules/*' | sort)

if [ "${found}" = 0 ]; then
  echo "::warning:: no metadata.json found under ${PATH_REL}" >&2
fi

echo "==> regenerating per-module workflows"
./scripts/sync-workflows.sh

cat <<MSG

Done. Review modules.json, then:

  git add -A && git commit -m "Add ${NAME}" && git push

sync-modules.yml picks the new submodule up on its next poll; to build
it immediately, run "Release <module>" from the Actions tab.
MSG
