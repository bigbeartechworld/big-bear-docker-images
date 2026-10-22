import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
VARIANTS = tuple(
    (application, executable, prefix)
    for application in ('btop', 'fastfetch', 'ncdu')
    for executable, prefix in (('gotty', 'GOTTY'), ('ttyd', 'TTYD'))
)


class TerminalCredentialTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.directory = Path(directory.name)
        for command, body in (
            ('gotty', 'printf \'%s\\n\' "$@"'),
            ('ttyd', 'printf \'%s\\n\' "$@"'),
            ('mkdir', 'exit 0'),
            ('cp', 'exit 0'),
        ):
            path = self.directory / command
            path.write_text(f'#!/bin/sh\n{body}\n')
            path.chmod(0o700)

    def launch(self, application, executable, credentials):
        filename = 'entrypoint.sh' if executable == 'gotty' else 'entrypoint.ttyd.sh'
        return subprocess.run(
            ['/bin/sh', str(ROOT / 'Apps' / application / filename)],
            env={
                'PATH': str(self.directory),
                'HOME': str(self.directory),
                'TMPDIR': str(self.directory),
                'NCDU_PATH': '/dummy-data',
                **credentials,
            },
            cwd=self.directory,
            capture_output=True,
            text=True,
            timeout=5,
            check=False,
        )

    def test_enabled_authentication_rejects_missing_or_empty_credentials(self):
        for application, executable, prefix in VARIANTS:
            for suffix in ('USER', 'PASS'):
                name = f'{prefix}_AUTH_{suffix}'
                for value in (None, ''):
                    with self.subTest(application=application, executable=executable,
                                      credential=name, value=value):
                        credentials = {
                            f'{prefix}_AUTH_ENABLED': 'true',
                            f'{prefix}_AUTH_USER': 'dummy-admin',
                            f'{prefix}_AUTH_PASS': 'dummy-password',
                        }
                        if value is None:
                            credentials.pop(name)
                        else:
                            credentials[name] = value
                        result = self.launch(application, executable, credentials)
                        self.assertNotEqual(result.returncode, 0)
                        self.assertIn(name, result.stderr)
                        self.assertEqual(result.stdout, '')

    def test_enabled_authentication_forwards_credentials_as_one_argument(self):
        for application, executable, prefix in VARIANTS:
            with self.subTest(application=application, executable=executable):
                result = self.launch(application, executable, {
                    f'{prefix}_AUTH_ENABLED': 'true',
                    f'{prefix}_AUTH_USER': 'dummy-admin',
                    f'{prefix}_AUTH_PASS': 'dummy password;$(literal)',
                })
                self.assertEqual(result.returncode, 0, result.stderr)
                expected = ['-p', '7681', '-w' if executable == 'gotty' else '-W',
                            '-c', 'dummy-admin:dummy password;$(literal)', application]
                if application == 'ncdu':
                    expected.append('/dummy-data')
                self.assertEqual(result.stdout.splitlines(), expected)

    def test_explicitly_disabled_authentication_retains_the_fixed_utility(self):
        for application, executable, prefix in VARIANTS:
            with self.subTest(application=application, executable=executable):
                result = self.launch(application, executable, {
                    f'{prefix}_AUTH_ENABLED': 'false',
                })
                self.assertEqual(result.returncode, 0, result.stderr)
                expected = ['-p', '7681', '-w' if executable == 'gotty' else '-W', application]
                if application == 'ncdu':
                    expected.append('/dummy-data')
                self.assertEqual(result.stdout.splitlines(), expected)


if __name__ == '__main__':
    unittest.main()
