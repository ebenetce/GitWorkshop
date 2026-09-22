# Working with Git and MATLAB

A hands-on MATLAB workshop for using Git to manage code, collaborate
confidently, and turn a project into a testable, packageable toolbox.

The workshop uses both MATLAB's Git interface (`gitrepo`) and command-line
Git. They operate on the same repository and commit history, so participants
can choose the workflow that best fits their day-to-day work.

## What you will learn

- The Git working tree, staging area, commits, branches, and remotes.
- How to inspect, stage, review, commit, merge, and share changes.
- How MATLAB Projects provide a consistent path and working environment.
- A practical MATLAB toolbox layout with source, tests, documentation, and
  reproducible build tasks.
- How to run code checks, unit tests, documentation generation, and toolbox
  packaging with `buildtool`.

## Repository contents

| Path | Purpose |
| --- | --- |
| `Workshop.m` | Plain-text MATLAB live script containing the workshop. |
| `ExampleFiles.zip` | Example SVAR toolbox code, tests, data, and documentation used in the workshop. |
| `buildfile.m` | Defines `check`, `test`, `doc`, and `package` build tasks. |
| `tbx/` | Toolbox source and documentation after completing the example-model section. |
| `tests/` | Unit tests for the example toolbox after completing the example-model section. |
| `public/` | Generated test and coverage reports. |
| `releases/` | Generated `.mltbx` toolbox packages. |

## Get started

Clone the repository, open MATLAB in the repository root, and open
`Workshop.m`:

```matlab
open("Workshop.m")
```

Work through the sections in order. The workshop intentionally creates files,
commits changes, switches branches, and moves the example files into the
toolbox layout, so run it in a disposable clone rather than in a repository
containing work you need to preserve.

MATLAB's Git API supports the core workflow directly. If Git is installed on
your system, the workshop also demonstrates its command-line interface:

```matlab
!git --version
```

## Build the example toolbox

After completing the example-model section, discover the available tasks:

```matlab
buildtool -tasks
```

Use the individual quality gates while developing:

```matlab
buildtool check
buildtool test
buildtool doc
```

Create the toolbox package with:

```matlab
buildtool package
```

The package task runs `check`, `test`, and `doc` first, then writes
`releases/svar.mltbx`. Test and coverage reports are written to `public/`.
These generated outputs should not normally be committed.

## Requirements

- MATLAB with support for plain-text live code, MATLAB Projects, and
  `buildtool`.
- Git is optional for the MATLAB Git API exercises, but required for the
  command-line Git exercises.
- MATLAB DocMaker is used by the documentation build task. The task installs
  it automatically when needed.

## Collaboration workflow

Start with `git status`, pull compatible remote work, and create a focused
branch for each change. Before committing, run the relevant build tasks and
review the staged diff:

```bash
git status
git diff --staged
```

Commit related changes together with a meaningful message, then push the
branch and open a review according to your team's process.
