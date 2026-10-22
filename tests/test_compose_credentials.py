import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
CONFIGURATIONS = []
for application, service, credentials in (
    ('big-bear-casaos-user-management', 'big-bear-casaos-user-management',
     ('ADMIN_USERNAME', 'ADMIN_PASSWORD')),
    ('minio', 'big-bear-minio', ('MINIO_ROOT_USER', 'MINIO_ROOT_PASSWORD')),
    ('odysseus', 'big-bear-odysseus', ('ODYSSEUS_ADMIN_PASSWORD',)),
):
    directory = ROOT / 'Apps' / application
    if application != 'big-bear-casaos-user-management':
        directory /= 'compose'
    for variant in ('docker-compose.yml', 'docker-compose.dev.yml', 'docker-compose.prod.yml'):
        CONFIGURATIONS.append((directory / variant, service, credentials))

for application in ('btop', 'fastfetch', 'ncdu'):
    CONFIGURATIONS.append((
        ROOT / 'Apps' / application / 'docker-compose.yml',
        f'big-bear-{application}',
        ('GOTTY_AUTH_USER', 'GOTTY_AUTH_PASS'),
    ))


class ComposeCredentialTests(unittest.TestCase):
    def setUp(self):
        self.docker = shutil.which('docker')
        if not self.docker:
            self.fail('Docker CLI with the Compose plugin must already be installed.')
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.directory = directory.name
        self.environment = {
            'PATH': os.environ.get('PATH', os.defpath),
            'HOME': self.directory,
            'TMPDIR': self.directory,
            'DOCKER_CONFIG': self.directory,
        }

    def render(self, path, credentials):
        return subprocess.run(
            [self.docker, 'compose', '--env-file', os.devnull,
             '--project-name', 'credential-regression', '-f', str(path),
             'config', '--format', 'json'],
            env={**self.environment, **credentials},
            cwd=self.directory,
            capture_output=True,
            text=True,
            timeout=20,
            check=False,
        )

    def dummy_credentials(self, names):
        return {name: f'dummy-{name}-value-$literal: with spaces' for name in names}

    def test_missing_or_empty_credentials_reject_configuration(self):
        for path, service, names in CONFIGURATIONS:
            for name in names:
                for value in (None, ''):
                    with self.subTest(path=str(path), credential=name, value=value):
                        credentials = self.dummy_credentials(names)
                        if value is None:
                            credentials.pop(name)
                        else:
                            credentials[name] = value
                        result = self.render(path, credentials)
                        self.assertNotEqual(result.returncode, 0)
                        self.assertIn(name, result.stderr)

    def test_explicit_credentials_reach_the_service_unchanged(self):
        for path, service, names in CONFIGURATIONS:
            with self.subTest(path=str(path)):
                credentials = self.dummy_credentials(names)
                result = self.render(path, credentials)
                self.assertEqual(result.returncode, 0, result.stderr)
                environment = json.loads(result.stdout)['services'][service]['environment']
                for name, value in credentials.items():
                    self.assertEqual(environment[name], value)
                if service == 'big-bear-odysseus':
                    self.assertEqual(environment['AUTH_ENABLED'], 'true')
                if 'GOTTY_AUTH_PASS' in names:
                    self.assertEqual(environment['GOTTY_AUTH_ENABLED'], 'true')


if __name__ == '__main__':
    unittest.main()
