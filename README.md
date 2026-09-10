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
| `openmetrics` | [openmetrics-module](https://github.com/logos-co/openmetrics-module) | `main` |
| `logos_delivery_demo` | [logos-delivery-demo](https://github.com/logos-co/logos-delivery-demo) | `main` |
| `chat_ui` | [logos-chat-ui](https://github.com/logos-co/logos-chat-ui) | `master` |

`lez_core` is here as a dependency of `liblogos_lez_rln_module`.
`logos_delivery_demo` and `chat_ui` are UI modules over `delivery_module`
and `chat_module`.

Seven submodules, eight modules — `logos-rln-modules` holds two. The
module list is the matrix in `release-all.yml`, not `.gitmodules`.

## Building

Run **Release <module>** from the Actions tab, or **Release all
modules** for the whole catalog, or:

```bash
./scripts/catalog.sh release-all --watch
```

Each build takes the tip of the branch `.gitmodules` records for that
module, so a release needs no submodule bump beforehand. The submodule
pointer is left where it is — builds leave no trace in the catalog
beyond their release — and because a branch moves, two runs can produce
different packages.

A module whose commit hasn't moved is skipped without building, so
re-running costs one API call per module.

To build something else — a feature branch, or an older commit — fill in
`module_ref` with a branch, tag or sha from the module's own repository.
The literal `pointer` builds the commit the submodule pointer names.

The pointers are still worth advancing now and then so the catalog
records what it published:

```bash
git submodule update --remote
git commit -am "Advance submodule pointers"
git push
```

Builds also start on their own once a module repository is wired to send
a `repository_dispatch` — `module-pushed.yml` receives it, advances that
submodule and releases. See
[`docs/notify-workflow.md`](docs/notify-workflow.md) for the sending half
and the token it needs.

## Versions

Each build is versioned from the module's `metadata.json` plus its commit
count and sha — `delivery_module` at `3770771` publishes as
`0.2.1-130.g3770771`. `metadata.json` is rewritten in the build
checkout only; the module repository is untouched.

These are pre-release versions, so they rank below a plain `0.2.1`. Don't
publish a release build of the same version here.

Releases are never deleted, so expect the `index` rebuild to slow down as
they accumulate — it re-downloads every published `.lgx` each run.

## Adding a module

```bash
./scripts/add-module.sh https://github.com/logos-co/<repo> <branch>
```

Then add its path to the matrix in `release-all.yml`.

## How it differs from the release catalog

Same machinery, both from the
[`logos-modules-release-base`](https://github.com/logos-co/logos-modules-release-base)
template. The one difference is
`version_template: "{version}-{commits}.g{short_sha}"` in
`_release-module.yml`: every commit gets its own version, so the
release tag is unique per commit and the action's "skip if already
published" gate means "skip unless this commit is new".
