# Local delivery checks

Acceptance contract, written before implementation, 2026-09-26.
Base: 7922d70090f3b968af23a9e080c0e5df1cfcb59a.

## Scope and source of truth

`.github/workflows/grindar.yml` remains the executable source of truth for
the `grindar` and `ridning` checks. The local runner reads its actual run
blocks, not a second list of check commands. The existing G8 inventory and
behavior tests remain mandatory. CI still executes the checks independently.

This is not all CI: `dubbel-sanning`, other workflows, publication, Studio
runtime and product acceptance are outside this runner. The runner itself
does not provision dependencies, install hooks or publish anything.
Run only reviewed repository code, in an isolated checkout: the existing
checks generate build files and reports. This tool is not a sandbox.
The known-command denylist rejects common direct provisioning forms, including
npm install/ci/i/add, npx, yarn, pnpm, pip/pip3 install, curl, wget, sudo and
apt/apt-get. It is not a shell parser: indirect commands, invoked scripts and
network access need code review. G8 independently rejects unannounced calls;
neither check is a universal security boundary.

## Invariants and acceptance cases

1. Every in-scope check runs in workflow order with its original strict Bash
   block. CI-only provisioning is recognized by exact content; changes to
   a provisioning block must stop planning, not silently skip new commands.
   Only the two existing PyYAML installation lines are removed from mixed
   setup/check blocks, after checking their complete command body.
2. Planning does not run checks or install anything. Execution requires an
   explicit flag. Missing input, dependencies, unsupported CI execution
   semantics or an empty job produce a nonzero result, never PASS.
3. A failed command or pipeline stops the chain. A failed build cannot run
   a stale generated result. Each step starts in the repository root, like CI.
4. A new check is included automatically; the independent G8 inventory must
   also approve it. Missing/deleted checks remain detectable by G8.
5. Results name the scope, HEAD, dirty state and workflow digest. `--run`
   rejects any initially modified, staged or untracked file before preflight
   or checks. There is no dirty override. PASS requires unchanged HEAD and
   workflow digest at the end. Generated reports may dirty the checkout;
   final status is printed, not silently reset. This identity check does not
   prove the absence of concurrent writes to every source file: the caller
   must use an isolated checkout without other writers.
   A stopped chain reports how many checks were not run.
6. The selected Bash path is printed before preflight. On Windows,
   WindowsApps and System32 Bash paths are rejected before process launch,
   including explicit selections. Use an existing Git Bash installation.

Positive cases: real workflow planning; successful multi-step fixture;
arguments and paths with spaces; nested Bash execution; step cwd isolation.
Negative cases: missing input, nonzero command, pipeline failure, failed
build plus stale output, changed setup block, extra conditional/environment
semantics, missing/empty job, missing dependencies, unavailable Bash,
known installation variants, dirty starts, changed HEAD/workflow and Windows
Bash aliases. Stable identity with generated reports is a positive control.
Tests use temporary fixtures, never mutations of the shared production tree.

## Usage

`python tools/fore-leverans.py --plan` prints the checks without executing them.
`python tools/fore-leverans.py --preflight` checks files and installed tools.
`python tools/fore-leverans.py --run` runs preflight and then the whole scope.
`--bash PATH` selects an existing Bash executable (Git Bash on Windows).
Launch from an initialized Git Bash terminal on Windows so its standard
tools are on PATH; selecting the executable alone does not configure PATH.
Windows WSL launcher aliases are not supported by this runner.

Use a clean isolated checkout for `--run`, never another writer's working
directory. Existing checks overwrite generated files including
`qa/pre-tobias/RAPPORT.md` and `qa/pre-tobias/WORLD_MANIFEST.json`, and produce
build/test output. Preserve needed outputs separately before another run;
this tool never resets, stashes or cleans files for you. Planning and
preflight may inspect a dirty checkout, but do not constitute check PASS.

The launching Python needs PyYAML. Within Bash, `python3` must match the CI
Python minor version and have PyYAML; Node must match the CI major version.
Luau, sha256sum and the CI-pinned Playwright with its Chromium must already
be installed. The runner diagnoses missing dependencies, never installs them.
Luau is currently downloaded from upstream `latest` in CI, so exact Luau
version reproducibility remains a known gap, not a claim made by this tool.
CI currently pins Playwright 1.49.1 while package.json declares 1.55.0;
this package does not silently upgrade or reconcile either version.

## Delivery discipline

Tobias' 2026-09-26 handover makes Codex the sole production writer and Claude
the independent design/code reviewer. Before coding: observable invariants,
positive cases and counterexamples. Before review: focused tests, attempted
falsification, the full relevant chain or explicit blockers. Review the exact
candidate, consolidate fixes, record severity/reopened findings/rounds/time.
Small engine checks need a predeclared hypothesis, candidate and isolated
data-safe environment. Full player acceptance remains a separate final step.
Future push, merge and publication require separate authorization.
