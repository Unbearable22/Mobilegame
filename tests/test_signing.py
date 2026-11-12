"""Signing must fail closed and never rotate or expose credentials."""
import importlib.util
import base64
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('setup_debug_signing', ROOT / 'tools/setup_debug_signing.py')
signing = importlib.util.module_from_spec(spec)
if spec.loader and Path(spec.origin).exists():
    spec.loader.exec_module(signing)


class SigningTests(unittest.TestCase):
    def test_missing_configuration_fails_closed(self):
        self.assertTrue(hasattr(signing, 'select_signing'), 'Signing selection must require explicit configuration')
        with self.assertRaisesRegex(ValueError, 'Missing'):
            signing.select_signing({}, Path('/missing/keytool'))

    def test_partial_and_blank_configuration_never_fall_back(self):
        self.assertTrue(hasattr(signing, 'select_signing'), 'Signing validation is missing')
        for env in ({'CHAIN_REACT_SIGNING_ALIAS': 'debug'},
                    {'CHAIN_REACT_SIGNING_KEYSTORE': ' '},
                    {'CHAIN_REACT_SIGNING_STORE_PASSWORD': 'credential-must-stay-private'}):
            with self.subTest(env=list(env)):
                with self.assertRaises(ValueError) as caught:
                    signing.select_signing(env, Path('/missing/keytool'), allow_ephemeral=True)
                self.assertNotIn('credential-must-stay-private', str(caught.exception))

    def test_invalid_key_rejected_without_credentials(self):
        self.assertTrue(hasattr(signing, 'select_signing'), 'Signing validation is missing')
        env = {'CHAIN_REACT_SIGNING_KEYSTORE': '/missing/private.keystore',
               'CHAIN_REACT_SIGNING_ALIAS': 'debug',
               'CHAIN_REACT_SIGNING_STORE_PASSWORD': 'must-not-leak-store',
               'CHAIN_REACT_SIGNING_KEY_PASSWORD': 'must-not-leak-key'}
        with self.assertRaises(ValueError) as caught:
            signing.select_signing(env, Path('/missing/keytool'))
        self.assertNotIn('must-not-leak', str(caught.exception))

    def test_ci_materialization_requires_complete_secrets_or_explicit_optin(self):
        self.assertTrue(hasattr(signing, 'prepare_ci'), 'CI signing preparation is missing')
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / 'identity'
            for env in ({}, {'ANDROID_DEBUG_KEY_ALIAS': 'debug'},
                        {'ANDROID_DEBUG_STORE_PASSWORD': 'do-not-expose'}):
                with self.assertRaises(ValueError) as caught:
                    signing.prepare_ci(env, target)
                self.assertNotIn('do-not-expose', str(caught.exception))
                self.assertFalse(target.exists())
            self.assertEqual(signing.prepare_ci({}, target, True), 'ephemeral-nonpersistent')
            self.assertFalse(target.exists())
            with self.assertRaises(ValueError):
                signing.prepare_ci({'ANDROID_DEBUG_KEY_ALIAS': 'debug'}, target, True)
            env = dict(zip(signing.SECRET_NAMES, (base64.b64encode(b'key-bytes').decode(),
                                                  'debug', 'private-store', 'private-key')))
            self.assertEqual(signing.prepare_ci(env, target), 'persistent-debug')
            config = json.loads((target / 'signing-config.json').read_text())
            self.assertEqual(Path(config['CHAIN_REACT_SIGNING_KEYSTORE']).read_bytes(), b'key-bytes')
            self.assertEqual(target.stat().st_mode & 0o777, 0o700)
            self.assertEqual((target / 'signing-config.json').stat().st_mode & 0o777, 0o600)
            with self.assertRaises(ValueError):
                signing.prepare_ci(env, target)

    def test_proxy_passes_passwords_only_by_environment(self):
        with tempfile.TemporaryDirectory() as tmp:
            executable = Path(tmp) / 'apksigner'
            executable.write_text('#!/usr/bin/env python3\nimport json, sys\nprint(json.dumps(sys.argv[1:]))\n')
            executable.chmod(0o700)
            env = dict(os.environ, CHAIN_REACT_REAL_APKSIGNER=str(executable),
                       CHAIN_REACT_SIGNING_STORE_PASSWORD='store-must-not-leak',
                       CHAIN_REACT_SIGNING_KEY_PASSWORD='key-must-not-leak')
            result = subprocess.run([sys.executable, str(ROOT / 'tools/setup_debug_signing.py'),
                                     '--apksigner-proxy', 'sign', '--ks-pass', 'pass:placeholder', 'debug.apk'],
                                    env=env, text=True, capture_output=True, check=True)
            self.assertNotIn('must-not-leak', result.stdout + result.stderr)
            self.assertEqual(json.loads(result.stdout), ['sign', '--key-pass',
                             'env:CHAIN_REACT_SIGNING_KEY_PASSWORD', '--ks-pass',
                             'env:CHAIN_REACT_SIGNING_STORE_PASSWORD', 'debug.apk'])

    @unittest.skipUnless(shutil.which('keytool') and os.environ.get('CHAIN_REACT_REAL_APKSIGNER'),
                         'Android apksigner and keytool required')
    def test_two_apks_keep_the_selected_certificate(self):
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            keytool = Path(shutil.which('keytool'))
            config = signing.create_identity(directory / 'identity', keytool)
            values = json.loads(config.read_text())
            expected = signing.select_signing(values, keytool)['certificate_sha256']
            env = dict(os.environ, **values)
            for number in (1, 2):
                apk = directory / f'fixture-{number}.apk'
                with zipfile.ZipFile(apk, 'w') as archive:
                    archive.writestr('AndroidManifest.xml', b'signing fixture')
                    archive.writestr('classes.dex', bytes([number]))
                signed = subprocess.run([sys.executable, str(ROOT / 'tools/setup_debug_signing.py'),
                                         '--apksigner-proxy', 'sign', '--min-sdk-version', '24',
                                         '--ks', values['CHAIN_REACT_SIGNING_KEYSTORE'],
                                         '--ks-key-alias', values['CHAIN_REACT_SIGNING_ALIAS'],
                                         '--ks-pass', 'pass:placeholder', str(apk)],
                                        env=env, capture_output=True, text=True)
                self.assertNotIn(values['CHAIN_REACT_SIGNING_STORE_PASSWORD'], signed.stdout + signed.stderr)
                self.assertEqual(signed.returncode, 0, signed.stderr)
                verified = subprocess.run([env['CHAIN_REACT_REAL_APKSIGNER'], 'verify',
                                           '--min-sdk-version', '24', '--print-certs', str(apk)],
                                          env=env, capture_output=True, text=True, check=True)
                self.assertIn('Signer #1 certificate SHA-256 digest: ' + expected, verified.stdout)

    @unittest.skipUnless(shutil.which('keytool'), 'keytool required')
    def test_durable_key_reused_and_wrong_password_rejected(self):
        self.assertTrue(hasattr(signing, 'create_identity'), 'Durable identity creation is missing')
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp) / 'signing'
            keytool = Path(shutil.which('keytool'))
            config = signing.create_identity(directory, keytool)
            env = json.loads(config.read_text())
            key = Path(env['CHAIN_REACT_SIGNING_KEYSTORE'])
            original = key.read_bytes()
            first = signing.select_signing(env, keytool)
            second = signing.select_signing(env, keytool)
            self.assertEqual(first['certificate_sha256'], second['certificate_sha256'])
            self.assertEqual(len(first['certificate_sha256']), 64)
            self.assertEqual(key.read_bytes(), original)
            self.assertEqual(directory.stat().st_mode & 0o777, 0o700)
            self.assertEqual(config.stat().st_mode & 0o777, 0o600)
            self.assertEqual(key.stat().st_mode & 0o777, 0o600)
            with self.assertRaises(ValueError):
                signing.create_identity(directory, keytool)
            self.assertEqual(key.read_bytes(), original)
            for field in ('CHAIN_REACT_SIGNING_STORE_PASSWORD', 'CHAIN_REACT_SIGNING_KEY_PASSWORD', 'CHAIN_REACT_SIGNING_ALIAS'):
                bad = dict(env, **{field: 'bad-secret-value'})
                with self.assertRaises(ValueError) as caught:
                    signing.select_signing(bad, keytool)
                self.assertNotIn('bad-secret-value', str(caught.exception))
            self.assertNotIn(env['CHAIN_REACT_SIGNING_STORE_PASSWORD'], json.dumps(first))

    @unittest.skipUnless(shutil.which('keytool'), 'keytool required')
    def test_ephemeral_requires_optin_and_reports_nonpersistent(self):
        self.assertTrue(hasattr(signing, 'select_signing'), 'Ephemeral selection is missing')
        with tempfile.TemporaryDirectory() as tmp:
            env = {}
            result = signing.select_signing(env, Path(shutil.which('keytool')), allow_ephemeral=True,
                                            ephemeral_directory=Path(tmp) / 'ephemeral')
            self.assertEqual(result['mode'], 'ephemeral-nonpersistent')
            self.assertFalse(result['persistent'])
            self.assertEqual(len(result['certificate_sha256']), 64)
            self.assertTrue(Path(env['CHAIN_REACT_SIGNING_KEYSTORE']).is_file())


if __name__ == '__main__':
    unittest.main()
