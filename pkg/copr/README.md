# Fedora COPR packaging

RPM packaging for Zeal, plus the automation that publishes it to
[Fedora COPR](https://copr.fedorainfracloud.org/). COPR is the Fedora analogue of
a Launchpad PPA: it rebuilds binaries from an uploaded *source* RPM, once per
enabled chroot (Fedora release × architecture). One workflow,
`publish-copr.yaml`, feeds two projects depending on its trigger:

| Flow    | COPR project            | Trigger                                       |
| ------- | ----------------------- | --------------------------------------------- |
| Release | `zealdocs/zeal`         | GitHub release (or manual run with a version) |
| Nightly | `zealdocs/zeal-nightly` | daily `cron` (or manual run with no version)  |

Both flows build the source RPM in GitHub Actions and submit it with `copr-cli`.
The nightly flow runs on a daily schedule rather than a per-push COPR webhook:
COPR has no built-in daily timer like Launchpad's "build daily", and a webhook
would rebuild on *every* push, straining the shared build farm. The scheduled run
is guarded so it skips when `main` has not advanced since the last build — the
"build daily, if changed" behaviour Launchpad provides natively, matching the PPA's
own `nightly` channel.

## Layout

- `zeal.spec` — the RPM spec (Qt 6). `%build`/`%install` are thin `%cmake` macro
  calls because CMake already installs the binary, `.desktop`, AppStream metainfo,
  and icons under the prefix (see `assets/freedesktop/CMakeLists.txt`). toml++ and
  cpp-httplib are header-only and bundled in `src/contrib`, so they are not
  `BuildRequires`.

The `Version:` tag is a placeholder (`0.0.0`). Both flows override it by passing
`--define "zeal_version <version>"` to `rpmbuild`, so the spec carries no version
to keep in sync. Release builds pass the clean tag (`0.8.2`); nightly builds pass
a snapshot derived from `git describe` (`0.8.2^15.gabcdef`).

## Target chroots

Zeal requires **Qt ≥ 6.4.2** (`src/app/CMakeLists.txt`), so the enabled chroots
must ship Qt 6.4.2 or newer — every currently supported Fedora release qualifies.
Chroots are selected on the COPR project itself (Settings → not in this repo), so
adding or retiring a Fedora release needs no change here.

## Release uploads (`publish-copr.yaml`)

On a published release (or via **Run workflow** with a version), the workflow
builds a pristine tarball from the tag, regenerates the spec's `%changelog` with a
single dated entry, builds a source RPM, and submits it with
`copr-cli build zealdocs/zeal <srpm>`. It waits for the build so a failing chroot
fails the workflow.

### One-time setup (releases)

1. Create the COPR project `zealdocs/zeal` (or a Fedora group project,
   `@zealdocs/zeal` — update `COPR_PROJECT_STABLE` in `publish-copr.yaml` to match)
   and enable the desired Fedora chroots.
2. Generate an API token at <https://copr.fedorainfracloud.org/api/>. It yields a
   ready-made config block:

   ```ini
   [copr-cli]
   login = ...
   username = ...
   token = ...
   copr_url = https://copr.fedorainfracloud.org
   ```

3. Store that entire block verbatim as the repository secret `COPR_API_TOKEN`.
   The workflow writes it to `~/.config/copr`. Tokens expire (~6 months) — refresh
   the secret when COPR stops accepting it.

## Nightly builds (daily `cron`)

The same workflow runs on a daily schedule with no version, which builds a nightly
snapshot from `main` and submits it to `zealdocs/zeal-nightly`. The snapshot version
is `git describe`-derived (`0.8.2^15.gabcdef`); the `^` makes each build sort *above*
the last release but *below* the next one (`0.8.2 < 0.8.2^15.gabcdef < 0.8.3`), so a
published release always supersedes the nightlies that led to it — the RPM analogue
of the PPA nightly's `-0~{revtime}`.

Before building, the workflow asks COPR for the latest build's version and skips
when it already matches the current `main` (`copr-cli get-package … --with-latest-build`).
Because the version embeds the commit, COPR's own record is the source of truth —
no state is stored in the repo — and a failed or absent build still differs, so it
is retried. The result is "build daily, only if changed", which Launchpad provides
natively and COPR does not.

### One-time setup (nightly)

Create the COPR project `zealdocs/zeal-nightly` (or `@zealdocs/zeal-nightly` —
update `COPR_PROJECT_NIGHTLY` in `publish-copr.yaml` to match) and enable the same
chroots as the release project. No additional secret is needed; the scheduled run
reuses `COPR_API_TOKEN`.

## Local testing

Build a source RPM the way the workflow does, then build the binary in `mock`
against a Fedora chroot:

```sh
VERSION=0.8.2
ZEAL=~/zeal   # your checkout

mkdir -p ~/rpmbuild/SOURCES ~/rpmbuild/SPECS

# Pristine tarball, named to match Source0. Use the release tag, or HEAD/a branch
# to test unreleased changes.
git -C "$ZEAL" archive --prefix="zeal-${VERSION}/" "v${VERSION}" \
    | gzip -9 > ~/rpmbuild/SOURCES/zeal-${VERSION}.tar.gz

cp "$ZEAL/pkg/copr/zeal.spec" ~/rpmbuild/SPECS/

rpmbuild -bs ~/rpmbuild/SPECS/zeal.spec \
    --define "_topdir $HOME/rpmbuild" \
    --define "zeal_version ${VERSION}"

# Build the binary RPM against the default mock chroot (e.g. fedora-rawhide-x86_64).
mock ~/rpmbuild/SRPMS/zeal-${VERSION}-1*.src.rpm
```
