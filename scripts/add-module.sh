#!/usr/bin/env bash
# Add a module to this catalog: registers it as a git submodule under
# submodules/ and generates its release workflow from
# .github/workflows/release-module.yml.template.
#
# Usage:
#   ./scripts/add-module.sh <git-url> <branch> [module-name] [module-path]
#
# The branch is required: sync-modules.yml advances a submodule to the
# tip of the branch recorded in .gitmodules, and one added without a
# branch is never built again.
#
# For a repository holding several modules, run this once for the
# submodule and then copy the generated workflow per module, pointing
# module_path at each subdirectory.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

URL="${1:-}"
BRANCH="${2:-}"
if [ -z "${URL}" ] || [ -z "${BRANCH}" ]; then
  echo "usage: $0 <git-url> <branch> [module-name] [module-path]" >&2
  exit 2
fi

REPO="$(basename "${URL%.git}")"
PATH_REL="submodules/${REPO}"
MODULE_PATH="${4:-${PATH_REL}}"
TEMPLATE=".github/workflows/release-module.yml.template"

if [ -e "${PATH_REL}" ]; then
  echo "error: ${PATH_REL} already exists" >&2
  exit 1
fi

git submodule add -b "${BRANCH}" "${URL}" "${PATH_REL}"

NAME="${3:-$(jq -r '.name' "${MODULE_PATH}/metadata.json")}"
WORKFLOW=".github/workflows/release-${NAME//_/-}.yml"
sed -e "s|__MODULE_PATH__|${MODULE_PATH}|g" -e "s|__MODULE__|${NAME}|g" \
  "${TEMPLATE}" > "${WORKFLOW}"

cat <<MSG

Added ${NAME} (${MODULE_PATH}) and wrote ${WORKFLOW}.
Add it to the matrix in release-all.yml and sync-modules.yml, then:

  git add -A && git commit -m "Add ${NAME}" && git push
MSG
