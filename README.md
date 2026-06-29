# project_tools

Small reusable Ada helpers for project-local check programs.

This crate intentionally provides low-level building blocks only: text searches, filesystem predicates, reusable requirement checks, release-check wrappers, Alire manifest checks, raw file prefix checks, simple file appends, generated-artifact shell checks, optional-tool shell checks, and process execution in a selected directory. Release policy, project layout, and test-suite expectations stay in each consuming project.

## Build

```sh
alr build
```

## Tests

The AUnit test suite lives in `tests`.

```sh
cd tests
alr build
./bin/project_tools_tests
cd ..
alr test
```

## Release Verification

Run these checks before every project_tools release:

```sh
alr build
alr exec -- gnatprove -P project_tools.gpr --level=0 --mode=check
alr test
cd tests
alr build
./bin/project_tools_tests
cd ..
cd public_api_smoke
alr build
./bin/project_tools_public_api_smoke
cd ..
cd tools
alr build
cd ..
tools/bin/check_all
```

The GNATprove legality check enforces SPARK legality for enabled units such as the pure `Project_Tools.Text` helpers. See `docs/SPARK.md` for the proof scope.

## Public API Smoke Test

`public_api_smoke` is a tiny crate that depends on `project_tools` through a local Alire pin and imports the public facade and child packages like an external consumer.

```sh
cd public_api_smoke
alr build
```

## API Documentation

GNATdoc configuration lives in `docs/api.gpr`.

```sh
cd docs
gnatdoc -P api.gpr -O api
```

Generated HTML goes under `docs/api/`; it is documentation output, not part of the normal build.

## Intended Use

Use this crate from repository-local tools such as release checkers, AUnit-suite checkers, documentation checkers, or source-staging helpers when they need common filesystem, text, manifest, or process operations. Keep project-specific policy in the consuming crate: this crate should not know which crates a product releases, which README wording a project requires, or which command sequence makes a release valid. The `tools/check_generated_artifacts.sh` and `tools/optional_tool.sh` scripts provide shared mechanics while the consuming project supplies its own generator command, artifact list, and smoke checks.

## Packages

`Project_Tools.Text` contains small string and text-file helpers: substring search, non-overlapping count, and reading a text file into an unbounded string.

`Project_Tools.Files` contains filesystem predicates, requirement checks, raw file reading, prefix checks, filtered tree copying, release source tree copying, and append helpers. Use `Name_List` for simple directory-entry names and `Path_List` for full filesystem paths.

`Project_Tools.Processes` contains wrappers around `GNAT.OS_Lib.Spawn` for running a program in a selected directory, either failing the current tool or returning the child status.

`Project_Tools.Release_Checks` contains root-relative release assertion wrappers for check programs, plus absolute installed-artifact checks and a `Run` rename for process steps.

`Project_Tools.Tree_Checks` contains recursive tree hygiene checks, including generated Python artifact checks, forbidden-token checks, and non-empty generated `.stderr` log rejection.

`Project_Tools.Alire_Manifests` is the stable facade for Alire manifest helpers. It is backed by two child packages:

- `Project_Tools.Alire_Manifests.Validation` for manifest and staged-source checks.
- `Project_Tools.Alire_Manifests.Staging` for copying manifests, build overlays, dependency manifests, and publish/build manifest swaps.

Consumers should normally use the facade package unless they have a reason to depend on only the validation or staging half.

## Examples

Check a release manifest template:

```ada
Project_Tools.Alire_Manifests.Require_No_Local_Pins
  ("alire.release.toml", Quiet => True);
Project_Tools.Alire_Manifests.Require_Release_Dependencies
  ("alire.release.toml",
   [Ada.Strings.Unbounded.To_Unbounded_String ("dep_a"),
    Ada.Strings.Unbounded.To_Unbounded_String ("dep_b")],
   Quiet => True);
```

Copy a release source tree while skipping build artifacts:

```ada
Project_Tools.Files.Copy_Release_Source_Tree
  (".",
   "/tmp/example-release",
   [Ada.Strings.Unbounded.To_Unbounded_String ("obj"),
    Ada.Strings.Unbounded.To_Unbounded_String ("bin")],
   [Ada.Strings.Unbounded.To_Unbounded_String ("alire.lock")],
   Quiet => True);
```

Run a command and inspect the status:

```ada
Status := Project_Tools.Processes.Run_Status
  (Label   => "build staged crate",
   Dir     => "/tmp/example-release",
   Program => Alr_Path,
   Args    => Build_Args,
   Quiet   => True);
```

## Failure Behavior

Requirement helpers report a diagnostic unless `Quiet` is true, set the process exit status to failure, and raise `Program_Error`. Callers that intentionally test failure paths should catch `Program_Error` and reset the exit status before continuing.

## License

MIT OR Apache-2.0 WITH LLVM-exception
