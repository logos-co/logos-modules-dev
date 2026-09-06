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

To build something other than the pointer — a feature branch, or an
older commit — run **Release <module>** and fill in `module_ref` with a
branch, tag or sha from the module's own repository. The submodule
pointer here is left alone, so the build leaves no trace in the catalog
beyond its release; and because a branch moves, two runs naming the same
branch can produce different packages.

Automatic builds are the next iteration: each module repository
dispatching to this one on a push to its default branch.

## Versions

Each build's version is derived from the module's `metadata.json` plus
its commit count and sha, so a build of `delivery_module` at commit
`3770771eba53` publishes as `0.2.1-130.g3770771eba53`. `metadata.json`
is rewritten in the build checkout only; the module repository is not
touched.

`{commits}` is a separate numeric identifier because SemVer compares
those numerically. `git describe`'s `0.2.1-10-gabc` is one alphanumeric
identifier and sorts *below* `0.2.1-2-gabc`, which would leave clients
resolving an old build as latest.

These are all pre-release versions, so they rank below a plain `0.2.1`.
Don't mix a released build of the same version into this catalog — it
would outrank every per-commit build of it.

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
