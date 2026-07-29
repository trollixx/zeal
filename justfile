# Zeal dev and release recipes.
# Uses CMake presets defined in CMakePresets.json.
# Run `just` (no args) to see the recipe list.

set shell := ["bash", "-cu"]
set windows-shell := ["sh", "-cu"]
set positional-arguments

# Default build preset; override with `just preset=name <recipe>`.
preset := env_var_or_default("PRESET", "dev")

# OS-specific preset selector for the build-time profiler.
timetrace_preset := if os() == "windows" { "timetrace-windows" } else { "timetrace-unix" }

[private]
default:
    @just --list

# Configure a build directory using the current preset.
[group('dev')]
configure *args:
    cmake --preset {{preset}} "$@"

# Build using the current preset.
[group('dev')]
build:
    cmake --build --preset {{preset}}

# Build and run Zeal; args go to zeal.
[group('dev')]
run *args: build
    ./build/{{preset}}/zeal "$@"

# Requires the WiX toolset on Windows for the MSI.
# Build distributable packages for the current preset.
[group('dev')]
package: build
    cmake --build --preset {{preset}} --target package

# Configure, build, and run the test suite.
[group('dev')]
test:
    cmake --preset testing
    cmake --build --preset testing
    ctest --preset testing

# Run clang-format over the tree.
[group('dev')]
format *args:
    pwsh tools/run-clang-format.ps1 {{args}}

# Depends on `build` so AUTOUIC/AUTOMOC/AUTORCC headers exist.
# Run clang-tidy over the tree or given files.
[group('dev')]
lint *args: build
    pwsh tools/run-clang-tidy.ps1 {{args}}

# Run clazy Qt-aware checks.
[group('dev')]
clazy *args: build
    pwsh tools/run-clazy.ps1 {{args}}

# Requires Clang (clang-cl on Windows) and ClangBuildAnalyzer on PATH.
# Profile build time and emit a ClangBuildAnalyzer report.
[group('dev')]
analyze-build-time:
    cmake --preset {{timetrace_preset}}
    cmake --build --preset {{timetrace_preset}}
    ClangBuildAnalyzer --all build/{{timetrace_preset}} build/{{timetrace_preset}}/cba.bin
    ClangBuildAnalyzer --analyze build/{{timetrace_preset}}/cba.bin

# Re-emit the ClangBuildAnalyzer report from an existing timetrace build.
[group('dev')]
analyze-build-time-report:
    ClangBuildAnalyzer --analyze build/{{timetrace_preset}}/cba.bin

# Invoke the preset's clean target.
[group('dev')]
clean:
    cmake --build --preset {{preset}} --target clean

# Generate release notes for the given version, insert the corresponding
# <release> entry into the appdata, and bump CMakeLists.txt versions.
# Review the resulting changes with `git diff` before running `just release-push`.
# Maintainer use only.
[group('release')]
release-prepare version:
    bash tools/release-prepare.sh {{version}}

# Commit appdata + version bump, push, create the draft release with the
# generated notes, then tag and push the tag (which triggers build CI).
# CI publishes the release once every build job succeeds.
# `remote` controls which remote (and matching GitHub repo) receives the push;
# default is `origin` (works for fork testing). For an upstream release, run
# `just release-push 0.8.2 upstream` (or whatever you've named the upstream remote).
# The commit and tag steps are skipped if already done, so the same version can
# be pushed to a fork first and then promoted to upstream.
# Maintainer use only.
[group('release')]
release-push version remote="origin":
    bash tools/release-push.sh {{version}} {{remote}}

# Delete the draft release, the remote tag, and the local tag for a version,
# undoing `just release-push` so it can be run again. Refuses to delete a
# release that is already published. Missing pieces are skipped.
# Maintainer use only.
[group('release')]
release-delete version remote="origin":
    bash tools/release-delete.sh {{version}} {{remote}}
