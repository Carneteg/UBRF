#!/usr/bin/env python3
"""Local delivery runner: contract tests with real Bash and isolated files."""
import copy
import importlib.util
import os
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location('fore_leverans', Path(__file__).with_name('fore-leverans.py'))
RUNNER = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = RUNNER
SPEC.loader.exec_module(RUNNER)
BASH = shutil.which(os.environ.get('UBRF_TEST_BASH', 'bash'))


def check(name='check', command='echo checked', required='input.txt'):
    return {'name': name, 'run': 'set -euo pipefail\ntest -f ' + required +
            ' || { echo "missing input" >&2; exit 1; }\n' + command + '\n'}


def workflow():
    actions = [{'uses': 'actions/checkout@v4'},
               {'uses': 'actions/setup-node@v4', 'with': {'node-version': '20'}},
               {'uses': 'actions/setup-python@v5', 'with': {'python-version': '3.12'}}]
    return {'jobs': {
        'grindar': {'runs-on': 'ubuntu-latest', 'steps': copy.deepcopy(actions) + [
            {'name': 'Luau', 'run': 'set -euo pipefail\n' + RUNNER.LUAU_SETUP + '\n'},
            check('G8', RUNNER.PIP + '\npython3 tools/testa-grindar-workflow.py', 'tools/testa-grindar-workflow.py'),
            check('inputs', RUNNER.PIP + '\npython3 tools/testa-grindar-workflow.py --forhandskoll', 'tools/testa-grindar-workflow.py'),
            check()]},
        'ridning': {'runs-on': 'ubuntu-latest', 'steps': copy.deepcopy(actions) + [
            check('browser setup', RUNNER.PLAYWRIGHT_SETUP, 'tools/ridtest.mjs'), check('web')]}}}


class Planning(unittest.TestCase):
    def test_only_exact_setup_is_removed(self):
        plan = RUNNER.build_plan(workflow())
        self.assertEqual(len(plan.checks), 4)
        self.assertEqual((plan.python, plan.node), ('3.12', '20'))
        self.assertIn('tools/ridtest.mjs', plan.inputs)
        for item in plan.checks:
            self.assertNotIn('install', item.script)
        self.assertEqual(plan.checks[-1].script, workflow()['jobs']['ridning']['steps'][-1]['run'])

    def test_new_check_included_in_order(self):
        data = workflow()
        data['jobs']['grindar']['steps'].append(check('added', 'echo newer'))
        self.assertEqual([x.name for x in RUNNER.build_plan(data).checks], ['G8', 'inputs', 'check', 'added', 'web'])

    def test_changed_setup_never_silently_skipped(self):
        for job, index in [('grindar', 3), ('grindar', 4), ('grindar', 5), ('ridning', 3)]:
            with self.subTest(job=job, index=index):
                data = workflow()
                data['jobs'][job]['steps'][index]['run'] += 'echo extra\n'
                with self.assertRaises(ValueError):
                    RUNNER.build_plan(data)

    def test_removed_and_duplicate_setup_or_guard_rejected(self):
        for index in (3, 4, 5):
            data = workflow()
            del data['jobs']['grindar']['steps'][index]
            with self.assertRaises(ValueError):
                RUNNER.build_plan(data)
        data = workflow()
        data['jobs']['ridning']['steps'].append(copy.deepcopy(data['jobs']['ridning']['steps'][3]))
        with self.assertRaises(ValueError):
            RUNNER.build_plan(data)

    def test_unknown_execution_semantics_rejected(self):
        for key, value in [('if', 'false'), ('continue-on-error', True), ('env', {'A': 'B'}),
                           ('shell', 'pwsh'), ('working-directory', 'elsewhere')]:
            for level in ('step', 'job'):
                with self.subTest(key=key, level=level):
                    data = workflow()
                    target = data['jobs']['grindar']
                    if level == 'step':
                        target = target['steps'][-1]
                    target[key] = value
                    with self.assertRaises(ValueError):
                        RUNNER.build_plan(data)

    def test_unknown_action_and_versions_rejected(self):
        for change in ({'uses': 'unknown/action@v1'},
                       {'uses': 'actions/setup-node@v4', 'with': {'node-version': 'latest'}}):
            data = workflow()
            data['jobs']['grindar']['steps'][1] = change
            with self.assertRaises(ValueError):
                RUNNER.build_plan(data)

    def test_missing_empty_jobs_and_global_env_rejected(self):
        for replacement in (None, {'runs-on': 'ubuntu-latest', 'steps': []}):
            data = workflow()
            data['jobs']['ridning'] = replacement
            with self.assertRaises(ValueError):
                RUNNER.build_plan(data)
        data = workflow()
        data['env'] = {'LOCAL_CI_DIFFERENCE': '1'}
        with self.assertRaises(ValueError):
            RUNNER.build_plan(data)

    def test_expression_unstrict_or_installing_check_rejected(self):
        for script in ('echo not-strict', check(command='echo ${{ github.sha }}')['run'],
                       check(command='npm install anything')['run']):
            data = workflow()
            data['jobs']['grindar']['steps'][-1]['run'] = script
            with self.assertRaises(ValueError):
                RUNNER.build_plan(data)


class Execution(unittest.TestCase):
    def setUp(self):
        self.assertIsNotNone(BASH, 'Bash required; missing tests are not PASS. Set UBRF_TEST_BASH.')
        self.tmp = tempfile.TemporaryDirectory(prefix='ubrf delivery ')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root / 'input.txt').write_text('fixture', encoding='utf-8')

    def plan(self, *commands):
        return RUNNER.Plan(tuple(RUNNER.Check('fixture', str(i), check(command=c)['run'], 'input.txt')
                                 for i, c in enumerate(commands)), ('input.txt',), '3.12', '20')

    def test_real_shell_runs_arguments_and_spaces(self):
        result = RUNNER.run_checks(self.plan('printf "%s" "hello world" > "space name.txt"'), self.root, BASH)
        self.assertEqual(result, 0)
        self.assertEqual((self.root / 'space name.txt').read_text(), 'hello world')

    def test_each_step_starts_in_repo_root(self):
        result = RUNNER.run_checks(self.plan('mkdir sub; cd sub', 'pwd > cwd.txt'), self.root, BASH)
        self.assertEqual(result, 0)
        self.assertTrue((self.root / 'cwd.txt').exists())

    def test_missing_input_fails_without_running_check(self):
        (self.root / 'input.txt').unlink()
        result = RUNNER.run_checks(self.plan('touch executed'), self.root, BASH)
        self.assertEqual(result, 1)
        self.assertFalse((self.root / 'executed').exists())

    def test_nonzero_and_pipeline_stop_later_checks(self):
        self.assertEqual(RUNNER.run_checks(self.plan('printf ok | cat > pipeline-ok'), self.root, BASH), 0)
        self.assertEqual((self.root / 'pipeline-ok').read_text(), 'ok')
        for command in ('exit 7', 'false | cat', 'false\nprintf wrong > after-failure'):
            with self.subTest(command=command):
                result = RUNNER.run_checks(self.plan(command, 'touch later'), self.root, BASH)
                self.assertEqual(result, 1)
                self.assertFalse((self.root / 'later').exists())
                self.assertFalse((self.root / 'after-failure').exists())

    def test_failed_build_cannot_execute_stale_file(self):
        (self.root / 'old.sh').write_text('touch stale-executed\n', encoding='utf-8')
        result = RUNNER.run_checks(self.plan('false\nbash old.sh'), self.root, BASH)
        self.assertEqual(result, 1)
        self.assertFalse((self.root / 'stale-executed').exists())

    def test_nested_bash_is_executed(self):
        (self.root / 'nested.sh').write_text('printf child > child.txt\n', encoding='utf-8')
        self.assertEqual(RUNNER.run_checks(self.plan('bash nested.sh'), self.root, BASH), 0)
        self.assertEqual((self.root / 'child.txt').read_text(), 'child')

    def test_absent_bash_and_input_reported_together(self):
        (self.root / 'input.txt').unlink()
        errors = RUNNER.preflight(self.plan('true'), self.root, None)
        self.assertEqual(len(errors), 2)
        self.assertTrue(any('input.txt' in error for error in errors))

    def test_dependency_failure_is_blocked_without_install(self):
        calls = []
        def missing(bash, script, root, capture):
            calls.append(script)
            return type('Result', (), {'returncode': 1, 'stdout': '', 'stderr': 'missing'})()
        with patch.object(RUNNER, 'shell', missing):
            errors = RUNNER.preflight(self.plan('true'), self.root, BASH)
        self.assertEqual(len(errors), 6)
        self.assertFalse(any(' install ' in script for script in calls))


class EntryPoint(unittest.TestCase):
    def test_default_plan_runs_nothing(self):
        with patch.object(RUNNER, 'load_workflow', return_value=workflow()), \
             patch.object(RUNNER, 'identity', return_value={'head': 'fixture'}), \
             patch.object(RUNNER, 'preflight') as preflight, \
             patch.object(RUNNER, 'run_checks') as run:
            self.assertEqual(RUNNER.main([]), 0)
            preflight.assert_not_called()
            run.assert_not_called()

    def test_blocked_preflight_never_runs_checks(self):
        with patch.object(RUNNER, 'load_workflow', return_value=workflow()), \
             patch.object(RUNNER, 'identity', return_value={'head': 'fixture'}), \
             patch.object(RUNNER, 'preflight', return_value=['missing dependency']), \
             patch.object(RUNNER, 'run_checks') as run:
            self.assertEqual(RUNNER.main(['--run']), 1)
            run.assert_not_called()

    def test_preflight_only_never_runs_checks(self):
        with patch.object(RUNNER, 'load_workflow', return_value=workflow()), \
             patch.object(RUNNER, 'identity', return_value={'head': 'fixture'}), \
             patch.object(RUNNER, 'preflight', return_value=[]), \
             patch.object(RUNNER, 'run_checks') as run:
            self.assertEqual(RUNNER.main(['--preflight']), 0)
            run.assert_not_called()


class Repository(unittest.TestCase):
    def test_actual_workflow_scripts_and_inventory(self):
        data = RUNNER.load_workflow(RUNNER.ROOT / RUNNER.WORKFLOW)
        plan = RUNNER.build_plan(data)
        self.assertGreater(len(plan.checks), 40)
        for check_ in plan.checks:
            step = next(s for s in data['jobs'][check_.job]['steps'] if s.get('name') == check_.name)
            expected = step['run'].replace(RUNNER.PIP + '\n', '')
            self.assertEqual(check_.script, expected)
        self.assertIn('bash roblox/tests/kor.sh\n', [x.script.splitlines(keepends=True)[-1] for x in plan.checks])
        self.assertFalse(any('pip install' in x.script for x in plan.checks))

    def test_duplicate_yaml_keys_fail(self):
        with tempfile.TemporaryDirectory(prefix='ubrf yaml ') as folder:
            path = Path(folder) / 'workflow.yml'
            path.write_text('jobs: {}\njobs: {}\n', encoding='utf-8')
            with self.assertRaisesRegex(ValueError, 'Dubbel'):
                RUNNER.load_workflow(path)


if __name__ == '__main__':
    unittest.main(verbosity=2)
