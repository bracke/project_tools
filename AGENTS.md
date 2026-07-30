# AGENTS.md

Guidance for AI agents working in the `project_tools` crate. **This file is the
canonical copy** and applies to every AI coding tool; `CLAUDE.md` imports it so
Claude Code sees the same text. Edit this file, not that one.

## What this is

`project_tools` is a pure Ada 2022 (Alire/GNAT) library of low-level helpers for
repository-local check programs: text searches, filesystem predicates, raw file
comparisons, Alire manifest checks, AUnit-suite checks, source-hygiene scans,
and process execution. Every package is `Project_Tools.*`. Its only dependency
is the toolchain.

**Roughly 36 projects in this workspace depend on it** — among them `cryptolib`,
`sshlib`, `devcert`, `versionlib`, `zlib`, `hostkit`, `webframework` and their
tooling crates, about 68 manifests in total. There is no other crate here with
that reach, and it is the fact that should govern every change: a signature
change is not a local edit. `public_api_smoke` exists precisely to catch this —
it consumes the public facade through a path pin the way an outside crate does.

Before changing an existing public subprogram, search the workspace for its
callers (`grep -rl "Project_Tools\.<Package>" ../*/`) and prefer adding to the
API over reshaping it.

`README.md` documents usage and the release checklist; `docs/SPARK.md` documents
the proof scope. Keep both accurate.

## The policy boundary this crate keeps

This crate provides *mechanics*; the consuming project supplies *policy*. It
must not know which crates a product releases, which README wording a project
requires, or what sequence makes a release valid. `check_generated_artifacts`
and `optional_tool` are the pattern: shared mechanism here, generator command
and artifact list in the caller. A helper that would need to be told about a
specific project belongs in that project's own tools crate.

## Build, test, style

- Toolchain: Alire GNAT 15 only, and pinned **exactly** — the manifest says
  `gnat_native = "=15.2.1"`, not a range. Validate with
  `alr exec -- gnatls --version`. Reach every tool through `alr exec -- ...`
  rather than `PATH`, so a system GNAT cannot be used by accident.
- Build: `alr build`.
- Tests: `(cd tests && alr build) && ./tests/bin/project_tools_tests` — AUnit;
  reports `Total Tests Run` with `Failed Assertions: 0`. `alr test` runs the
  same thing through the manifest's test action.
- Public-API smoke: `(cd public_api_smoke && alr build) && ./public_api_smoke/bin/project_tools_public_api_smoke`.
  A tiny crate that pins `project_tools` by path and imports the public facade
  the way an outside consumer does, so that it still compiles is most of the
  assertion; `check_all` builds it and runs it.
- Aggregate gate: `(cd tools && alr build) && tools/bin/check_all`, run from the
  crate root. This is the one to run before calling a change done. Its steps are
  three warnings-as-errors builds (see below), then `alr build`, GNATprove,
  `alr test`, the tests build, the AUnit suite, and the public-API smoke build
  and run; on top of those it scans the tree for the Ada-only tooling rule below
  and asserts that certain sources exist and that `README.md` still mentions
  them. It does **not** run `check_generated_artifacts` — that binary is for
  consuming projects to call, and `check_all` only checks that its source is
  present and documented.
- **Style and warnings are enforced, and which switches you get depends on the
  Alire build profile rather than on `project_tools.gpr`.** The manifest pins
  `"*" = "development"`, which supplies `-gnatwa`, `-gnatVa` and the full
  `-gnaty` set — but development only *reports* them. `--validation` adds
  `-gnatwe`, which makes each an error, and `check_all` runs it forced over the
  library, `tests/` and `public_api_smoke/`:

  ```sh
  alr build --validation -- -f
  ```

  Forced, because a warning surfaces only when its file recompiles. `tools/` is
  deliberately not gated: it holds the binary running the check, and relinking a
  running executable fails for reasons unrelated to style. All three gated
  crates were clean when this was switched on, so any breach you see is one you
  introduced.

## SPARK

Part of this crate is SPARK, and the legality check is **mandatory for every
release**, not optional:

```sh
alr exec -- gnatprove -P project_tools.gpr --level=0 --mode=check
```

`tools/bin/check_all` runs it. `--mode=check` is legality only, not proof of
absence of run-time errors — passing means the enabled units are legal SPARK,
not that they are proved. `docs/SPARK.md` lists which packages are in scope
(`Text`, `Files`, `Processes`, `Alire_Manifests` and children, `AUnit_Checks`,
`Security_Corpus`, `Tree_Checks`). Adding a construct SPARK rejects to one of
those packages breaks the release, so check before assuming a change is free.

## No scripts, and here it is enforced

The Ada-only tooling rule is not a convention in this crate — `check_all` walks
the tree and fails the build on any file with a `.sh`, `.bash`, `.zsh`, `.ksh`
or `.fish` extension, and on any file carrying a shebang. Generated directories
are skipped. Tooling that would be a shell script elsewhere is an Ada program
here; that is much of the reason this crate exists.

Helpers do invoke external commands, because checks have to run compilers and
provers. Keep the shell out of the argument: a command line is how a program is
invoked, not where logic goes.

## Platform code

`Project_Tools.Links` is the only per-OS package. `project_tools.gpr` selects it
with `Source_Dirs use ("src/", "src-" & Project_Tools_Config.Alire_Host_OS & "/")`,
so `src-linux/`, `src-macos/` and `src-windows/` are chosen by host name.

Note that `src-unsupported/project_tools-links.adb` exists but **nothing selects
it**: the `Source_Dirs` expression interpolates the host OS directly, so a host
Alire names anything else looks for `src-<that name>/` and fails rather than
falling back. Treat it as an unreferenced file, not as a working fallback, and
do not assume edits to it take effect anywhere.

Whichever backend the host does not build is compiled by nothing, so a shared
declaration can change under it unnoticed.

## When you change behavior

Update `README.md` and `docs/SPARK.md` where they are affected, add or adjust
the AUnit tests, run `tools/bin/check_all`, and — because of the reach noted
above — rebuild at least one consuming tools crate against the change before
calling it done.
