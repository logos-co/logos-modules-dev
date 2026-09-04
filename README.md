# logos-modules-dev

A Logos module catalog that publishes **one build per commit on each
module's default branch**, rather than one build per released version.

Point a client at it to run the tip of every module:

```
https://raw.githubusercontent.com/logos-co/logos-modules-dev/main/logos-repo.json
```

> These builds are unsigned, unreviewed, and pruned after a while. Use
> [`logos-modules-release`](https://github.com/logos-co/logos-modules-release)
> for anything that needs to keep working.

## What's in it

| Module | Source | Branch |
|---|---|---|
| `delivery_module` | [logos-delivery-module](https://github.com/logos-co/logos-delivery-module) | `master` |
| `chat_module` | [logos-chat-module](https://github.com/logos-co/logos-chat-module) | `master` |
| `liblogos_rln_module` | [logos-rln-modules](https://github.com/logos-co/logos-rln-modules) | `main` |
| `liblogos_lez_rln_module` | [logos-rln-modules](https://github.com/logos-co/logos-rln-modules) | `main` |
| `rln_membership_ui` | [logos-rln-modules](https://github.com/logos-co/logos-rln-modules) | `main` |
| `lez_core` | [logos-execution-zone-module](https://github.com/logos-blockchain/logos-execution-zone-module) | `main` |
| `libp2p_module` | [logos-libp2p-module](https://github.com/logos-co/logos-libp2p-module) | `master` |
| `rln_gifter_module` | [logos-rln-gifter](https://github.com/logos-co/logos-rln-gifter) | `master` |
| `keycard_capture_module` | [logos-rln-gifter](https://github.com/logos-co/logos-rln-gifter) | `master` |

`delivery_module`, `chat_module` and the three `logos-rln-modules`
modules are the ones actually wanted here; the rest are the dependency
closure — `chat_module` needs `delivery_module`, and `rln_membership_ui`
needs `lez_core`, `libp2p_module`, `rln_gifter_module` and
`keycard_capture_module`.

Six submodules, nine modules: `logos-rln-modules` holds three and
`logos-rln-gifter` holds two. **`modules.json` is the module list**, not
`.gitmodules`.

## How a build is triggered

GitHub does not notify this repository when a submodule it points at
moves, so `sync-modules.yml` polls instead — **every 30 minutes**:

1. `git ls-remote` reads the tip of each submodule's tracked branch.
2. Pointers that moved are written into the index and committed here.
3. Only the modules inside a moved submodule are released.

Polling means a build tracks the **branch tip**, not every intermediate
commit: three commits landing inside one interval produce one build, of
the last of them.

Nothing else fires automatically. `release-all.yml` (rebuild
everything), `release-<module>.yml` (rebuild one) and `unpublish.yml`
are all manual, from the Actions tab.

For instant builds instead of polling, each module repository would need
a `push` workflow dispatching to this one, plus a token with write
access here stored as a secret in each of the six — see
[`docs/instant-triggers.md`](docs/instant-triggers.md).

## Versions repeat, and that's expected

The tag carries the commit (`chat_module-1a2b3c4d5e6f`), but `version`
still comes from the module's `metadata.json` and only moves when
someone bumps it. So the catalog holds many builds all calling
themselves `0.2.2`.

Clients cope: `index.py` keys entries on `(version, rootHash)` and
orders same-version entries newest-first, so `versions[0]` is the newest
build. The package-manager UI will show the version repeated, separated
only by date.

## Retention

`prune-builds.yml` keeps the newest **10** builds per module, nightly.

This is not housekeeping — it is load-bearing. `rebuild-index`
downloads every published `.lgx` to read its manifest, on every run.
Without pruning, a per-commit catalog turns the index rebuild into an
hours-long job within weeks.

## Adding a module

```bash
./scripts/add-module.sh https://github.com/logos-co/<repo> [branch]
```

Adds the submodule tracking its default branch, registers every
`metadata.json` inside it in `modules.json`, and regenerates the
per-module workflows. Review `modules.json`, commit, push.

Editing `modules.json` by hand is fine too — follow it with
`./scripts/sync-workflows.sh`.

## Layout

```
.
├── modules.json                          # THE module list (9 modules)
├── logos-repo.json                       # catalog metadata clients read
├── .gitmodules                           # 6 repos, each with a tracked branch
├── scripts/
│   ├── add-module.sh                     # add a repo + register its modules
│   ├── sync-workflows.sh                 # regenerate per-module workflows
│   └── catalog.sh                        # run the workflows via `gh`
└── .github/workflows/
    ├── sync-modules.yml                  # the poll → bump → release cycle
    ├── prune-builds.yml                  # retention (keep 10 per module)
    ├── _release-module.yml               # tag scheme + signing, one place
    ├── release-module.yml.template        # generates the per-module files
    ├── release-<module>.yml              # one per module, manual
    ├── release-all.yml                   # rebuild everything, manual
    ├── rebuild-index.yml                 # rebuilds index.json after releases
    └── unpublish.yml                     # manual removal
```

## Relationship to the release catalog

Same machinery as
[`logos-modules-release`](https://github.com/logos-co/logos-modules-release),
both built from the
[`logos-modules-release-base`](https://github.com/logos-co/logos-modules-release-base)
template. The only pipeline difference is the tag: this catalog passes
`tag_template: "{name}-{short_sha}"` to
[`logos-modules-release-action`](https://github.com/logos-co/logos-modules-release-action),
which turns the "skip if already published" gate into "skip unless this
commit is new".

## Notes for cloning

```bash
git submodule update --init --recursive
```
