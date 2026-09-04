# logos-modules-dev

A Logos module catalog built from every commit on each module's default
branch, rather than from releases.

Add it to the package-manager UI / `lgpd` as:

```
https://raw.githubusercontent.com/logos-co/logos-modules-dev/main/logos-repo.json
```

Builds here are unsigned and untested. Use
[`logos-modules-release`](https://github.com/logos-co/logos-modules-release)
for anything that needs to keep working.

## Modules

| Module | Source | Branch |
|---|---|---|
| `delivery_module` | [logos-delivery-module](https://github.com/logos-co/logos-delivery-module) | `master` |
| `chat_module` | [logos-chat-module](https://github.com/logos-co/logos-chat-module) | `master` |
| `liblogos_rln_module` | [logos-rln-modules](https://github.com/logos-co/logos-rln-modules) | `main` |
| `liblogos_lez_rln_module` | [logos-rln-modules](https://github.com/logos-co/logos-rln-modules) | `main` |
| `lez_core` | [logos-execution-zone-module](https://github.com/logos-blockchain/logos-execution-zone-module) | `main` |

`lez_core` is here as a dependency of `liblogos_lez_rln_module`.

Four submodules, five modules — `logos-rln-modules` holds two. The
module list is the matrix in `release-all.yml`, not `.gitmodules`.

## Building

Everything is triggered by hand for now. Advance the submodules and
push:

```bash
git submodule update --remote
git commit -am "Advance submodule pointers"
git push
```

then run **Release all modules** from the Actions tab, or:

```bash
./scripts/catalog.sh release-all --watch
```

A module whose commit hasn't moved is skipped without building, so
re-running costs one API call per module.

Automatic builds are the next iteration: each module repository
dispatching to this one on a push to its default branch.

## Versions repeat

The tag carries the commit (`chat_module-1a2b3c4d5e6f`), but `version`
comes from the module's `metadata.json` and only moves when someone
bumps it, so the catalog holds many builds all calling themselves
`0.2.2`. Clients sort same-version entries newest-first, so the tip
build is still the one they resolve.

Releases are never deleted. Expect the `index` rebuild to slow down as
they accumulate — it re-downloads every published `.lgx` each run.

## Adding a module

```bash
./scripts/add-module.sh https://github.com/logos-co/<repo> <branch>
```

Then add its path to the matrix in `release-all.yml`.

## How it differs from the release catalog

Same machinery, both from the
[`logos-modules-release-base`](https://github.com/logos-co/logos-modules-release-base)
template. The one difference is `tag_template: "{name}-{short_sha}"` in
`_release-module.yml`, which makes the action's "skip if already
published" gate mean "skip unless this commit is new".
