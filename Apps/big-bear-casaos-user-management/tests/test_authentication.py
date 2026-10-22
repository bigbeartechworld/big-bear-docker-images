import base64
import hashlib
import os
from pathlib import Path
import runpy
import sqlite3
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'app'))

with patch.dict(os.environ, {
    'ADMIN_USERNAME': 'test-admin',
    'ADMIN_PASSWORD': 'test-password',
}):
    import app as web
import user_management


class AccountMutationAuthenticationTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        database_path = str(Path(directory.name) / 'user.db')
        self.database = sqlite3.connect(database_path)
        self.addCleanup(self.database.close)
        self.database.execute(
            'CREATE TABLE o_users ('
            'id INTEGER PRIMARY KEY, username TEXT UNIQUE, password TEXT, '
            'role TEXT, created_at TEXT, updated_at TEXT)'
        )
        self.database.execute(
            'INSERT INTO o_users VALUES (?, ?, ?, ?, ?, ?)',
            (1, 'existing-user', 'initial-password-hash', 'admin', 'initial-time', None),
        )
        self.database.commit()
        for replacement in (
            patch.object(user_management, 'DB_PATH', database_path),
            patch.multiple(web, ADMIN_USERNAME='test-admin', ADMIN_PASSWORD='test-password'),
            patch.dict(web.app.config, TESTING=True, SECRET_KEY='test-session-key'),
        ):
            replacement.start()
            self.addCleanup(replacement.stop)
        self.client = web.app.test_client()

    def authorization(self, username='test-admin', password='test-password'):
        credentials = base64.b64encode(f'{username}:{password}'.encode()).decode()
        return {'Authorization': f'Basic {credentials}'}

    def rows(self):
        return self.database.execute('SELECT * FROM o_users ORDER BY id').fetchall()

    def test_missing_or_invalid_credentials_cannot_mutate_accounts(self):
        initial_rows = self.rows()
        requests = (
            ('/add_user', {'username': 'new-user', 'password': 'new-password'}),
            ('/edit_password', {'user_id': '1', 'new_password': 'new-password'}),
            ('/remove_user', {'user_id': '1'}),
        )
        credentials = (
            {},
            self.authorization(username='wrong-admin'),
            self.authorization(password='wrong-password'),
        )
        for path, data in requests:
            for headers in credentials:
                with self.subTest(path=path, authorization=headers):
                    response = self.client.post(path, data=data, headers=headers)
                    self.assertEqual(response.status_code, 401)
                    self.assertEqual(
                        response.headers['WWW-Authenticate'],
                        'Basic realm="Login Required"',
                    )
                    self.assertEqual(self.rows(), initial_rows)

    def test_administrator_can_create_account(self):
        response = self.client.post(
            '/add_user',
            data={'username': 'new-user', 'password': 'new-password'},
            headers=self.authorization(),
        )
        self.assertEqual(response.status_code, 302)
        self.assertEqual(response.headers['Location'], '/')
        rows = self.rows()
        self.assertEqual(len(rows), 2)
        self.assertEqual(rows[1][1:4], (
            'new-user', hashlib.md5(b'new-password').hexdigest(), 'admin',
        ))

    def test_administrator_can_change_account_password(self):
        response = self.client.post(
            '/edit_password',
            data={'user_id': '1', 'new_password': 'new-password'},
            headers=self.authorization(),
        )
        self.assertEqual(response.status_code, 302)
        self.assertEqual(response.headers['Location'], '/')
        rows = self.rows()
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0][:5], (
            1, 'existing-user', hashlib.md5(b'new-password').hexdigest(),
            'admin', 'initial-time',
        ))
        self.assertIsNotNone(rows[0][5])

    def test_administrator_can_delete_account(self):
        response = self.client.post(
            '/remove_user', data={'user_id': '1'}, headers=self.authorization(),
        )
        self.assertEqual(response.status_code, 302)
        self.assertEqual(response.headers['Location'], '/')
        self.assertEqual(self.rows(), [])

    def test_colon_in_administrator_password_allows_authenticated_operation(self):
        with patch.dict(os.environ, {
            'ADMIN_USERNAME': 'test-admin',
            'ADMIN_PASSWORD': 'test:password',
        }, clear=True):
            module = runpy.run_path(str(Path(web.__file__)))
        with patch.dict(module['app'].config, TESTING=True, SECRET_KEY='test-session-key'):
            response = module['app'].test_client().post(
                '/remove_user',
                data={'user_id': '1'},
                headers=self.authorization(password='test:password'),
            )
        self.assertEqual(response.status_code, 302)
        self.assertEqual(response.headers['Location'], '/')
        self.assertEqual(self.rows(), [])


class AdministratorCredentialConfigurationTests(unittest.TestCase):
    def load_application(self, environment):
        with patch.dict(os.environ, environment, clear=True):
            return runpy.run_path(str(Path(web.__file__)))

    def test_missing_or_blank_credentials_prevent_startup(self):
        environments = (
            {},
            {'ADMIN_USERNAME': 'test-admin'},
            {'ADMIN_PASSWORD': 'test-password'},
            {'ADMIN_USERNAME': '', 'ADMIN_PASSWORD': 'test-password'},
            {'ADMIN_USERNAME': 'test-admin', 'ADMIN_PASSWORD': ''},
            {'ADMIN_USERNAME': '  ', 'ADMIN_PASSWORD': 'test-password'},
            {'ADMIN_USERNAME': 'test-admin', 'ADMIN_PASSWORD': '  '},
        )
        for environment in environments:
            with self.subTest(environment=environment):
                with self.assertRaisesRegex(RuntimeError, 'ADMIN_USERNAME and ADMIN_PASSWORD'):
                    self.load_application(environment)

    def test_colon_in_username_prevents_startup(self):
        for username in ('test:admin', ':test-admin', 'test-admin:'):
            with self.subTest(username=username):
                with self.assertRaisesRegex(RuntimeError, 'ADMIN_USERNAME must not contain a colon'):
                    self.load_application({
                        'ADMIN_USERNAME': username,
                        'ADMIN_PASSWORD': 'test-password',
                    })

    def test_public_example_passwords_prevent_startup(self):
        for password in ('casaos', 'YOUR_SECURE_PASSWORD'):
            with self.subTest(password=password):
                with self.assertRaisesRegex(RuntimeError, 'public example password'):
                    self.load_application({
                        'ADMIN_USERNAME': 'test-admin',
                        'ADMIN_PASSWORD': password,
                    })

    def test_explicit_credentials_are_used_without_normalization(self):
        module = self.load_application({
            'ADMIN_USERNAME': 'private-admin',
            'ADMIN_PASSWORD': ' private-test-password ',
        })
        self.assertTrue(module['check_auth']('private-admin', ' private-test-password '))
        self.assertFalse(module['check_auth']('private-admin', 'private-test-password'))
        self.assertFalse(module['check_auth']('casaos', 'casaos'))
        self.assertFalse(module['check_auth']('admin', 'YOUR_SECURE_PASSWORD'))


if __name__ == '__main__':
    unittest.main()
