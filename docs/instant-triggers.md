# Instant triggers instead of polling

`sync-modules.yml` polls the module branches every 30 minutes. That is
the only mechanism that needs no changes outside this repository, and it
is what the catalog uses today.

Two properties follow from polling, and they are the reasons to consider
replacing it:

- **Latency.** A commit waits up to the poll interval before its build
  starts.
- **Coalescing.** Several commits landing inside one interval produce a
  single build, of the last one. If a build really is wanted for every
  intermediate commit, polling cannot provide it at any interval.

## The alternative

Each module repository gets a workflow on its default branch:

```yaml
name: Notify logos-modules-dev
on:
  push:
    branches: [master]        # or main
jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - uses: peter-evans/repository-dispatch@v3
        with:
          token: ${{ secrets.LOGOS_MODULES_DEV_TOKEN }}
          repository: logos-co/logos-modules-dev
          event-type: module-pushed
          client-payload: '{"repo": "${{ github.repository }}", "sha": "${{ github.sha }}"}'
```

and `sync-modules.yml` gains a matching trigger:

```yaml
on:
  repository_dispatch:
    types: [module-pushed]
```

The polling path stays as the safety net for a missed dispatch, exactly
as `rebuild-index.yml` keeps its 6-hourly schedule alongside its
dispatch trigger.

## What it costs

Six repositories across two organisations
(`logos-co` and `logos-blockchain`) each need the workflow and each need
`LOGOS_MODULES_DEV_TOKEN` — a PAT or GitHub App installation token with
write access to this catalog. That is one credential that can publish
here, stored in six places, and rotating it means six updates. A GitHub
App scoped to this repository is the better shape if this is done; a
classic PAT on a personal account is not.

Note that this still does not guarantee a build per commit: the
dispatch carries a sha, but `sync-modules.yml` advances the pointer to
whatever the branch tip is when it runs. Building an arbitrary
historical commit would mean passing the sha through to the pointer
bump.
