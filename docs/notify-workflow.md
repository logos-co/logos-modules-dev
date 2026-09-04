# Notifying the catalog from a module repository

`module-pushed.yml` here listens for a `repository_dispatch` of type
`module-pushed`. Each module repository sends one when its default
branch moves.

## The sending workflow

Add to the module repository as
`.github/workflows/notify-logos-modules-dev.yml`:

```yaml
name: Notify logos-modules-dev

on:
  push:
    branches: [master]      # main, for logos-rln-modules and logos-execution-zone-module

permissions: {}

jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - uses: peter-evans/repository-dispatch@ff45666b9427631e3450c54a1bcbee4d9ff4d7c0 # v3
        with:
          token: ${{ secrets.LOGOS_MODULES_DEV_TOKEN }}
          repository: logos-co/logos-modules-dev
          event-type: module-pushed
          client-payload: '{"repo": "${{ github.repository }}"}'
```

`repo` tells the catalog which submodule to advance. An unrecognised
value falls back to advancing all of them, so a typo costs a rebuild,
not a failure.

## The token

`LOGOS_MODULES_DEV_TOKEN` must be able to POST to
`/repos/logos-co/logos-modules-dev/dispatches`, which needs **Contents:
write** on this repository. A GitHub App installation scoped to
`logos-modules-dev` is the right shape; a classic PAT on a personal
account grants far more than this needs.

The same secret goes in all four repositories, so rotating it is four
updates.

## Repositories to add it to

| Repository | Branch |
|---|---|
| `logos-co/logos-delivery-module` | `master` |
| `logos-co/logos-chat-module` | `master` |
| `logos-co/logos-rln-modules` | `main` |
| `logos-blockchain/logos-execution-zone-module` | `main` |

`logos-execution-zone-module` is in a different organisation, so the
secret has to be provisioned there separately.

## What it does not give you

The catalog advances each submodule to whatever its branch tip is when
the workflow runs, not to the sha that triggered the dispatch. Pushes
landing close together still collapse into one build.
