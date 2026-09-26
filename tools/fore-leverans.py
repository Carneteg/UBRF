#!/usr/bin/env python3
"""Execute the reviewed Grindar workflow locally, without CI provisioning."""
import argparse
from dataclasses import dataclass
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
WORKFLOW = Path('.github/workflows/grindar.yml')
JOBS = ('grindar', 'ridning')
GUARD = re.compile(r'^test -f (\S+) \|\| .+$')
PIP = 'python3 -m pip install --quiet pyyaml'
LUAU_SETUP = '''curl -sSfL -o /tmp/luau.zip \\
  https://github.com/luau-lang/luau/releases/latest/download/luau-ubuntu.zip
unzip -o -q /tmp/luau.zip -d /tmp/luau
sudo install -m 0755 /tmp/luau/luau /usr/local/bin/luau
luau --help >/dev/null && echo "luau installerad"'''
PLAYWRIGHT_SETUP = '''npm install --no-save --no-package-lock playwright@1.49.1
npx playwright install --with-deps chromium'''


@dataclass(frozen=True)
class Check:
    job: str
    name: str
    script: str
    required: str


@dataclass(frozen=True)
class Plan:
    checks: tuple
    inputs: tuple
    python: str
    node: str


def load_workflow(path):
    try:
        import yaml
    except ImportError as exc:
        raise ValueError('PyYAML saknas i startande Python. Ingen installation gjord.') from exc

    class UniqueLoader(yaml.SafeLoader):
        pass

    def mapping(loader, node):
        result = {}
        for key, value in node.value:
            key = loader.construct_object(key)
            if key in result:
                raise ValueError('Dubbel YAML-nyckel: %s' % key)
            result[key] = loader.construct_object(value)
        return result

    UniqueLoader.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, mapping)
    return yaml.load(path.read_text(encoding='utf-8'), Loader=UniqueLoader)


def build_plan(data):
    """Only known setup is omitted; unsupported execution semantics fail closed."""
    if not isinstance(data, dict) or any(k in data for k in ('env', 'defaults')):
        raise ValueError('Workflowens globala env/defaults stods inte lokalt.')
    checks, inputs, versions = [], [], []
    setup = []
    for job in JOBS:
        config = data.get('jobs', {}).get(job)
        if not isinstance(config, dict) or set(config) != {'runs-on', 'steps'}:
            raise ValueError('Saknat jobb eller okanda jobbvillkor: ' + job)
        if config['runs-on'] != 'ubuntu-latest' or not isinstance(config['steps'], list):
            raise ValueError('Okand exekveringsmiljo: ' + job)
        actions = []
        count = len(checks)
        for step in config['steps']:
            if not isinstance(step, dict):
                raise ValueError('Ogiltigt steg i ' + job)
            if 'uses' in step:
                allowed = {'uses', 'with', 'name'}
                action = (step['uses'], step.get('with', {}))
                if set(step) - allowed:
                    raise ValueError('Okanda actionvillkor i ' + job)
                actions.append(action)
                continue
            if set(step) != {'name', 'run'} or not isinstance(step['run'], str):
                raise ValueError('Okanda stegsvillkor i ' + job)
            script = step['run']
            if '${{' in script:
                raise ValueError('GitHub-uttryck kan inte koras lokalt: ' + step['name'])
            lines = script.strip().splitlines()
            if not lines or lines[0] != 'set -euo pipefail':
                raise ValueError('Strikt Bash saknas: ' + step['name'])
            guard = GUARD.fullmatch(lines[1]) if len(lines) > 1 else None
            required = guard.group(1) if guard else ''
            if required:
                if Path(required).is_absolute() or '..' in Path(required).parts:
                    raise ValueError('Indata utanfor repot: ' + required)
                inputs.append(required)
            body = '\n'.join(lines[2:] if guard else lines[1:])
            if job == 'grindar' and not guard and body == LUAU_SETUP:
                setup.append('luau')
                continue
            if job == 'ridning' and required == 'tools/ridtest.mjs' and body == PLAYWRIGHT_SETUP:
                setup.append('playwright')
                continue
            if not guard:
                raise ValueError('Okand setup eller saknad indataassertion: ' + step['name'])
            if PIP in body:
                options = ('python3 tools/testa-grindar-workflow.py',
                           'python3 tools/testa-grindar-workflow.py --forhandskoll')
                if job != 'grindar' or required != 'tools/testa-grindar-workflow.py' or body not in [PIP + '\n' + x for x in options]:
                    raise ValueError('Andrad blandad setup/kontroll: ' + step['name'])
                setup.append('pyyaml-preflight' if body.endswith('--forhandskoll') else 'pyyaml-selftest')
                script = script.replace(PIP + '\n', '', 1)
            if re.search(r'\b(curl|sudo|npm install|npx playwright install|pip install)\b', script):
                raise ValueError('Okand installation i kontroll: ' + step['name'])
            checks.append(Check(job, step['name'], script, required))
        if len(checks) == count:
            raise ValueError('Tomt kontrolljobb: ' + job)
        if len(actions) != 3 or actions[0] != ('actions/checkout@v4', {}):
            raise ValueError('Okand actionkedja: ' + job)
        if actions[1][0] != 'actions/setup-node@v4' or set(actions[1][1]) != {'node-version'}:
            raise ValueError('Okand Node-setup: ' + job)
        if actions[2][0] != 'actions/setup-python@v5' or set(actions[2][1]) != {'python-version'}:
            raise ValueError('Okand Python-setup: ' + job)
        node, python = str(actions[1][1]['node-version']), str(actions[2][1]['python-version'])
        if not re.fullmatch(r'\d+', node) or not re.fullmatch(r'\d+\.\d+', python):
            raise ValueError('Versionerna maste vara explicit Node-major/Python-minor.')
        versions.append((python, node))
    if sorted(setup) != ['luau', 'playwright', 'pyyaml-preflight', 'pyyaml-selftest'] or len(set(versions)) != 1:
        raise ValueError('Setup saknas, dubbleras eller versioner skiljer mellan jobben.')
    return Plan(tuple(checks), tuple(dict.fromkeys(inputs)), *versions[0])


def shell(bash, script, root, capture=False):
    # Resolve the real outer shell before any child fixture modifies PATH.
    return subprocess.run([bash, '--noprofile', '--norc', '-e', '-o', 'pipefail', '-c', script],
                          cwd=root, text=True, encoding='utf-8', errors='replace',
                          capture_output=capture)


def preflight(plan, root, bash):
    errors = ['Saknad indata: ' + p for p in plan.inputs if not (root / p).is_file()]
    if not bash:
        return errors + ['Bash saknas. Ange --bash med en befintlig installation.']
    probes = [
        ('Bash och standardverktyg i PATH',
         'for tool in bash cat mkdir; do command -v "$tool" >/dev/null; done'),
        ('Python ' + plan.python + ' och PyYAML',
         "python3 -c 'import sys, yaml; print(sys.version); assert sys.version_info[:2] == " + str(tuple(map(int, plan.python.split('.')))) + "'"),
        ('Node ' + plan.node, "node -e 'console.log(process.version); if(process.versions.node.split(\".\")[0] !== \"" + plan.node + "\") process.exit(1)'"),
        ('Luau', 'luau --help >/dev/null'),
        ('sha256sum', 'sha256sum --version >/dev/null'),
        ('Playwright 1.49.1 och dess Chromium',
         "node -e 'const p=require(\"playwright\"); const v=require(\"playwright/package.json\").version; console.log(v); if(v!==\"1.49.1\" || !require(\"fs\").existsSync(p.chromium.executablePath())) process.exit(1)'"),
    ]
    for name, script in probes:
        result = shell(bash, 'set -euo pipefail\n' + script, root, capture=True)
        if result.returncode:
            errors.append(name + ': ' + (result.stdout + result.stderr).strip())
    return errors


def run_checks(plan, root, bash):
    for index, check in enumerate(plan.checks):
        print('[%d/%d] %s / %s' % (index + 1, len(plan.checks), check.job, check.name), flush=True)
        result = shell(bash, check.script, root)
        if result.returncode:
            print('FAIL: exit=%d; %d senare kontroller EJ KORDA.' %
                  (result.returncode, len(plan.checks) - index - 1), flush=True)
            return 1
    return 0


def identity(root):
    result = {}
    for name, args in (('head', ['rev-parse', 'HEAD']),
                       ('status', ['status', '--porcelain', '--untracked-files=normal'])):
        output = subprocess.run(['git', *args], cwd=root, capture_output=True,
                                text=True, encoding='utf-8', errors='replace')
        if output.returncode:
            raise ValueError('Git-identitet kunde inte lasas: ' + output.stderr.strip())
        result[name] = output.stdout.strip()
    result['workflow_sha256'] = hashlib.sha256((root / WORKFLOW).read_bytes()).hexdigest()
    return result


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--plan', action='store_true', help='Only list checks (default).')
    mode.add_argument('--preflight', action='store_true', help='Check existing inputs and tools.')
    mode.add_argument('--run', action='store_true', help='Preflight, then execute all checks.')
    parser.add_argument('--bash', help='Existing Bash executable; no installation.')
    args = parser.parse_args(argv)
    try:
        plan = build_plan(load_workflow(ROOT / WORKFLOW))
        print('SCOPE: Grindar/grindar + Grindar/ridning; INTE hela CI eller produktacceptans.')
        print('CI-setup kors INTE lokalt. Kontroller: %d.' % len(plan.checks))
        print(json.dumps(identity(ROOT), ensure_ascii=True))
        if not args.run and not args.preflight:
            for check in plan.checks:
                print('%s / %s' % (check.job, check.name))
            print('PLAN ONLY: inga kontroller korda.')
            return 0
        bash = shutil.which(args.bash or 'bash')
        errors = preflight(plan, ROOT, bash)
        if errors:
            print('BLOCKED: inga kontroller korda.\n' + '\n'.join(errors))
            return 1
        if not args.run:
            print('PREFLIGHT OK: inga kontroller korda.')
            return 0
        result = run_checks(plan, ROOT, bash)
        print('SLUTIDENTITET: ' + json.dumps(identity(ROOT), ensure_ascii=True))
        if result == 0:
            print('PASS: endast angivet kontrollscope, aktuell arbetskopia. Inte releaseacceptans.')
        return result
    except (ValueError, OSError, KeyError, TypeError) as exc:
        print('BLOCKED: ' + str(exc), file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
