#!/usr/bin/env bash
# Regenerate one per-module release workflow for every entry in
# modules.json, from .github/workflows/release-module.yml.template.
#
# Usage:
#   ./scripts/sync-workflows.sh [--check]
#
# --check verifies the generated files are up to date without writing
# (used by CI); it exits non-zero when modules.json and the workflows
# have drifted.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

CHECK=0
[ "${1:-}" = "--check" ] && CHECK=1

TEMPLATE=".github/workflows/release-module.yml.template"
[ -f "${TEMPLATE}" ] || { echo "error: ${TEMPLATE} not found" >&2; exit 1; }

slug() { printf '%s' "${1//_/-}"; }

want=()
drift=0

while read -r name path; do
  wf=".github/workflows/release-$(slug "${name}").yml"
  want+=("${wf}")
  rendered="$(sed -e "s|__MODULE_PATH__|${path}|g" -e "s|__MODULE__|${name}|g" "${TEMPLATE}")"
  if [ "${CHECK}" = 1 ]; then
    if [ ! -f "${wf}" ] || [ "$(cat "${wf}")" != "${rendered}" ]; then
      echo "drift: ${wf}"; drift=1
    fi
  else
    printf '%s\n' "${rendered}" > "${wf}"
    echo "wrote ${wf}"
  fi
done < <(jq -r '.modules[] | "\(.name) \(.path)"' modules.json)

# Per-module workflows for modules that left modules.json are stale.
for wf in .github/workflows/release-*.yml; do
  [ "${wf}" = ".github/workflows/release-all.yml" ] && continue
  keep=0
  for w in "${want[@]}"; do [ "${w}" = "${wf}" ] && keep=1; done
  if [ "${keep}" = 0 ]; then
    if [ "${CHECK}" = 1 ]; then echo "stale: ${wf}"; drift=1; else rm -v "${wf}"; fi
  fi
done

if [ "${CHECK}" = 1 ]; then
  [ "${drift}" = 0 ] && echo "workflows are in sync with modules.json"
  exit "${drift}"
fi
