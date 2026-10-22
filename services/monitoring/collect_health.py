#!/usr/bin/env python3
import datetime
import json
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[2]
SERVICES = ('webserver', 'php', 'mysql', 'redis', 'horizon', 'scheduler', 'reverb', 'meilisearch')


def command(args, timeout=10):
    return subprocess.run(args, cwd=ROOT, capture_output=True, text=True, check=True, timeout=timeout).stdout


def byte_value(value):
    match = re.fullmatch(r'\s*([\d.]+)\s*(B|kB|KB|MB|GB|TB|KiB|MiB|GiB|TiB)\s*', value)
    if not match:
        raise ValueError('Invalid size')
    units = {'B': 1, 'kB': 1000, 'KB': 1000, 'MB': 1000**2, 'GB': 1000**3, 'TB': 1000**4,
             'KiB': 1024, 'MiB': 1024**2, 'GiB': 1024**3, 'TiB': 1024**4}
    return int(float(match[1]) * units[match[2]])


def storage_usage(root, seconds=8, limit=200000):
    totals = {key: {'bytes': 0, 'files': 0} for key in ('screenshots', 'page_sources', 'crawler_tests', 'logs', 'other')}
    if not root.is_dir() or root.is_symlink():
        return {'categories': totals, 'complete': False, 'total_bytes': 0}
    deadline = time.monotonic() + seconds
    count = 0
    complete = True
    def error(_):
        nonlocal complete
        complete = False
    for directory, dirs, files in os.walk(root, followlinks=False, onerror=error):
        if time.monotonic() > deadline:
            return {'categories': totals, 'complete': False, 'total_bytes': sum(item['bytes'] for item in totals.values())}
        dirs[:] = [name for name in dirs if not (Path(directory) / name).is_symlink()]
        for name in files:
            if time.monotonic() > deadline or count >= limit:
                return {'categories': totals, 'complete': False, 'total_bytes': sum(item['bytes'] for item in totals.values())}
            path = Path(directory) / name
            try:
                info = path.lstat()
                if not stat.S_ISREG(info.st_mode):
                    continue
                relative = path.relative_to(root).as_posix()
                if relative.startswith('app/private/health/'):
                    continue
                if relative.startswith('logs/'):
                    key = 'logs'
                elif relative.startswith('app/private/crawler-tests/'):
                    key = 'crawler_tests'
                elif relative.startswith('app/private/crawler-data/sites/'):
                    key = 'screenshots' if name.endswith('.png') else 'page_sources'
                else:
                    key = 'other'
                totals[key]['bytes'] += info.st_size
                totals[key]['files'] += 1
                count += 1
            except OSError:
                complete = False
    return {'categories': totals, 'complete': complete, 'total_bytes': sum(item['bytes'] for item in totals.values())}


def collect():
    result = {'version': 1, 'checked_at': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'containers': [], 'errors': []}
    try:
        memory = dict((line.split(':', 1)[0], int(line.split()[1]) * 1024) for line in Path('/proc/meminfo').read_text().splitlines() if line.startswith(('MemTotal:', 'MemAvailable:')))
        result['memory'] = {'total_bytes': memory['MemTotal'], 'available_bytes': memory['MemAvailable'], 'used_bytes': memory['MemTotal'] - memory['MemAvailable']}
        disk = shutil.disk_usage(ROOT / 'app/storage')
        result['disk'] = {'total_bytes': disk.total, 'used_bytes': disk.used, 'free_bytes': disk.free}
        result['load'] = list(os.getloadavg())
        result['cpus'] = os.cpu_count()
    except (OSError, KeyError):
        result['errors'].append('Server resource readings unavailable.')
    try:
        result['storage'] = storage_usage(ROOT / 'app/storage')
    except OSError:
        result['errors'].append('Application file sizes unavailable.')
    try:
        ids = command(['docker', 'compose', 'ps', '-a', '-q']).split()
        containers = {}
        if ids:
            template = '{{.Id}}|{{index .Config.Labels "com.docker.compose.service"}}|{{.State.Status}}|{{if .State.Health}}{{.State.Health.Status}}{{end}}|{{.RestartCount}}|{{.HostConfig.Memory}}'
            for line in command(['docker', 'inspect', '--format', template, *ids]).splitlines():
                identifier, service, state, health, restarts, memory_limit = line.split('|')
                if service in SERVICES:
                    containers[service] = {'id': identifier, 'service': service, 'state': state, 'health': health or 'not_configured', 'restarts': int(restarts), 'memory_limit_bytes': int(memory_limit) or None, 'memory_bytes': None, 'cpu_percent': None}
            running = [item['id'] for item in containers.values() if item['state'] == 'running']
            if running:
                try:
                    stats = [json.loads(line) for line in command(['docker', 'stats', '--no-stream', '--no-trunc', '--format', '{{json .}}', *running], timeout=15).splitlines()]
                    for row in stats:
                        item = next((item for item in containers.values() if item['id'].startswith(row['ID'])), None)
                        if item:
                            item['memory_bytes'] = byte_value(row['MemUsage'].split('/')[0])
                            item['cpu_percent'] = float(row['CPUPerc'].rstrip('%'))
                except (subprocess.SubprocessError, KeyError, ValueError):
                    result['errors'].append('Container resource readings unavailable.')
        for service in SERVICES:
            item = containers.get(service, {'service': service, 'state': 'missing', 'health': 'unknown', 'memory_bytes': None, 'memory_limit_bytes': None, 'cpu_percent': None, 'restarts': None})
            item.pop('id', None)
            result['containers'].append(item)
    except (subprocess.SubprocessError, KeyError, ValueError):
        result['errors'].append('Container status unavailable.')
    return result


def main():
    # Outside the application's writable bind mount; PHP only receives a read-only mount.
    directory = ROOT / '.health'
    if directory.is_symlink():
        raise RuntimeError('Snapshot directory must not be a symlink')
    directory.mkdir(mode=0o755, exist_ok=True)
    descriptor, name = tempfile.mkstemp(prefix='.host-', dir=directory)
    try:
        with os.fdopen(descriptor, 'w') as output:
            json.dump(collect(), output, separators=(',', ':'))
        os.chmod(name, 0o644)
        os.replace(name, directory / 'host.json')
    finally:
        if os.path.exists(name):
            os.unlink(name)


if __name__ == '__main__':
    main()
