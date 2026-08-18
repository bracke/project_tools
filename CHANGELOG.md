# Changelog

Notable changes to project_tools. Format follows [Keep a Changelog](https://keepachangelog.com/1.1.0/);
versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

`alire.toml` says `0.1.0` and no tag exists, so the consumers that depend on
this crate depend on a **commit**: adash, hostkit and the rest pin it by path.
Until there is a tag, that commit is the version, and a consumer's release has
to record which one it was verified against.

This file starts where it was written rather than reconstructing fifty commits;
what came before is in `git log`, where each message says what changed and why.

## [Unreleased]

### Changed

- **`Project_Tools.TOML` reads a key whether or not the caller included its
  `=`.** The readers took the text after the key and required a value there, so
  a caller passing `"version"` rather than `"version = "` met the `=` where a
  value should be, got `Malformed`, and — through `String_Value_After` and its
  neighbours — `""` or zero. Two empty strings compare equal, which is how a
  check in Adash compared the version recorded in two files, read nothing out
  of either, and passed for years, including on runs made to prove it worked.

  `version`, `version =` and `version = ` now find the same value. Every caller
  in the workspace already passed the `=`, so nothing downstream changes shape;
  what changes is that the mistake no longer answers silently.

- **The first occurrence that parses is the answer.** The first match used to
  win even when it did not parse, and the first match is very often the word
  written in the comment above its own entry. Each parser walks occurrences
  until one yields a value, and reports `Malformed` only when none does.

### Added

- Coverage summaries, token-aware source scanning and fixture seeding.
- Managed process capture helpers, and a helper for a process's command output.
- Reusable workflow helper APIs, and a single-file copy helper.
- `Stale_Doc_Scaffolding`, a release check for documentation nobody finished.
- `Files.Any_File_Contains`, for source assertions that do not name a path.

### Fixed

- A line's value no longer carries a trailing carriage return, which made a
  value read on Windows differ from the same value read anywhere else.
- Bytes are printed as they were read.
- The build fails on warnings and style, rather than reporting them.

## Releasing

There is no release procedure here yet. The first thing one has to settle is
what a version means for a crate whose consumers all pin it by path: until they
stop, a tag here is a label on a commit rather than something Alire resolves.
