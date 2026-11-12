#!/usr/bin/env python3
"""Create a durable debug identity outside Git; optionally upload Actions Secrets."""
import argparse
import base64
import binascii
import hashlib
import json
import os
from pathlib import Path
import secrets
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
FIELDS = ('CHAIN_REACT_SIGNING_KEYSTORE', 'CHAIN_REACT_SIGNING_ALIAS',
          'CHAIN_REACT_SIGNING_STORE_PASSWORD', 'CHAIN_REACT_SIGNING_KEY_PASSWORD')
SECRET_NAMES = ('ANDROID_DEBUG_KEYSTORE_BASE64', 'ANDROID_DEBUG_KEY_ALIAS',
                'ANDROID_DEBUG_STORE_PASSWORD', 'ANDROID_DEBUG_KEY_PASSWORD')
DEFAULT_DIRECTORY = Path.home() / '.local/share/chain-react-signing'


def private_command(args, env):
    """Capture credential-tool diagnostics so errors never reflect private input."""
    result = subprocess.run([str(a) for a in args], env=env, capture_output=True)
    if result.returncode:
        raise ValueError('Signing key validation or creation failed; check key, alias and passwords')
    return result.stdout


def create_identity(directory, keytool):
    directory = directory.expanduser().resolve()
    if directory == ROOT or ROOT in directory.parents:
        raise ValueError('Signing identity must be stored outside the repository')
    if directory.exists():
        raise ValueError('Signing directory already exists; refusing to replace an identity')
    directory.mkdir(parents=True, mode=0o700)
    directory.chmod(0o700)
    key = directory / 'chain-react-debug.keystore'
    password = secrets.token_urlsafe(36)
    values = dict(zip(FIELDS, (str(key), 'chainreactdebug', password, password)))
    env = os.environ.copy()
    env.update(values)
    try:
        private_command([keytool, '-genkeypair', '-noprompt', '-storetype', 'JKS', '-keystore', key,
                         '-storepass:env', FIELDS[2], '-keypass:env', FIELDS[3], '-alias', values[FIELDS[1]],
                         '-dname', 'CN=Chain React Debug,O=Chain React,C=US', '-keyalg', 'RSA',
                         '-keysize', '3072', '-validity', '10000'], env)
        key.chmod(0o600)
        config = directory / 'signing-config.json'
        with open(config, 'x', opener=lambda path, flags: os.open(path, flags, 0o600)) as handle:
            json.dump(values, handle, indent=2)
            handle.write('\n')
        return config
    except Exception:
        # Keep a partial directory to prevent accidental replacement of a generated key.
        raise


def select_signing(env, keytool, allow_ephemeral=False, ephemeral_directory=None):
    values = [env.get(name, '') for name in FIELDS]
    configured = any(name in env for name in FIELDS)
    mode = 'persistent-debug'
    if not configured:
        if not allow_ephemeral:
            raise ValueError('Missing stable debug signing configuration; see docs/android-signing.md')
        if ephemeral_directory is None:
            raise ValueError('Explicit ephemeral signing directory is required')
        config = create_identity(ephemeral_directory, keytool)
        env.update(json.loads(config.read_text()))
        values = [env[name] for name in FIELDS]
        mode = 'ephemeral-nonpersistent'
    if not all(isinstance(value, str) and value.strip() for value in values):
        raise ValueError('Missing or blank signing fields; partial configuration cannot use ephemeral fallback')
    key = Path(values[0]).expanduser().resolve()
    if not key.is_file():
        raise ValueError('Signing keystore file does not exist')
    if key == ROOT or ROOT in key.parents:
        raise ValueError('Signing keystore must be outside the repository and artifacts')
    if key.stat().st_mode & 0o077:
        raise ValueError('Signing keystore must have owner-only permissions (chmod 600)')
    env[FIELDS[0]] = str(key)
    command_env = os.environ.copy()
    command_env.update(env)
    common = [keytool, '-keystore', key, '-storepass:env', FIELDS[2], '-alias', values[1]]
    # A certificate alone is insufficient: certreq proves the private key and key password work.
    private_command([*common, '-certreq', '-keypass:env', FIELDS[3]], command_env)
    certificate = private_command([*common, '-exportcert'], command_env)
    return {'mode': mode, 'persistent': mode == 'persistent-debug',
            'certificate_sha256': hashlib.sha256(certificate).hexdigest(),
            'debug_only': True, 'prior_v0_5_0_update_compatibility': 'unverified'}


def upload_config(config, repo, keytool):
    values = json.loads(config.read_text())
    select_signing(values, keytool)
    def gh(*args, data=None):
        result = subprocess.run(['gh', *args], input=data, capture_output=True)
        if result.returncode:
            raise ValueError('GitHub Actions Secrets access failed (possibly HTTP 403); owner must use an authorized token')
        return result.stdout
    existing = {entry['name'] for entry in json.loads(gh('secret', 'list', '--repo', repo, '--json', 'name'))}
    if existing.intersection(SECRET_NAMES):
        raise ValueError('Signing Secrets already exist; refusing to overwrite any existing configuration')
    # Verify permission before uploading the first secret.
    gh('api', f'repos/{repo}/actions/secrets/public-key')
    payloads = (base64.b64encode(Path(values[FIELDS[0]]).read_bytes()),
                values[FIELDS[1]].encode(), values[FIELDS[2]].encode(), values[FIELDS[3]].encode())
    for name, payload in zip(SECRET_NAMES, payloads):
        gh('secret', 'set', name, '--repo', repo, data=payload)
    names = {entry['name'] for entry in json.loads(gh('secret', 'list', '--repo', repo, '--json', 'name'))}
    if not set(SECRET_NAMES).issubset(names):
        raise ValueError('Secrets readback incomplete; owner must inspect repository configuration')
    print('Configured and read back Secret names: ' + ', '.join(SECRET_NAMES))


def prepare_ci(env, directory, allow_ephemeral=False):
    values = [env.get(name, '') for name in SECRET_NAMES]
    if not any(values):
        if allow_ephemeral:
            return 'ephemeral-nonpersistent'
        raise ValueError('Missing Actions signing Secrets; see docs/android-signing.md')
    if not all(isinstance(value, str) and value.strip() for value in values):
        raise ValueError('Incomplete Actions signing Secrets; no ephemeral fallback is permitted')
    try:
        key_bytes = base64.b64decode(values[0], validate=True)
    except (ValueError, binascii.Error):
        raise ValueError('Invalid keystore base64; no ephemeral fallback is permitted') from None
    if not key_bytes:
        raise ValueError('Empty signing keystore')
    directory = directory.expanduser().resolve()
    if directory == ROOT or ROOT in directory.parents or directory.exists():
        raise ValueError('CI signing directory must be new and outside the repository')
    directory.mkdir(parents=True, mode=0o700)
    directory.chmod(0o700)
    key = directory / 'chain-react-debug.keystore'
    with open(key, 'xb', opener=lambda path, flags: os.open(path, flags, 0o600)) as handle:
        handle.write(key_bytes)
    config = dict(zip(FIELDS, (str(key), *values[1:])))
    with open(directory / 'signing-config.json', 'x',
              opener=lambda path, flags: os.open(path, flags, 0o600)) as handle:
        json.dump(config, handle)
    return 'persistent-debug'


def apksigner_proxy():
    """Godot receives a placeholder; real passwords reach apksigner only via env."""
    args = sys.argv[2:]
    if args and args[0] == 'sign':
        try:
            position = args.index('--ks-pass')
        except ValueError:
            raise SystemExit('Signing proxy requires an explicit password source')
        args[position + 1] = 'env:' + FIELDS[2]
        args[1:1] = ['--key-pass', 'env:' + FIELDS[3]]
    os.execve(os.environ['CHAIN_REACT_REAL_APKSIGNER'],
              [os.environ['CHAIN_REACT_REAL_APKSIGNER'], *args], os.environ.copy())


def main():
    if len(sys.argv) > 1 and sys.argv[1] == '--apksigner-proxy':
        apksigner_proxy()
        return
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('create', 'upload', 'inspect', 'prepare-ci'))
    parser.add_argument('--directory', type=Path, default=DEFAULT_DIRECTORY)
    parser.add_argument('--keytool', type=Path, default=Path('keytool'))
    parser.add_argument('--repo', default='Unbearable22/Mobilegame')
    parser.add_argument('--allow-ephemeral-signing', action='store_true')
    args = parser.parse_args()
    try:
        if args.action == 'prepare-ci':
            mode = prepare_ci(os.environ, args.directory, args.allow_ephemeral_signing)
            print('Signing mode: ' + mode)
            if mode == 'ephemeral-nonpersistent':
                print('::warning::Explicit NONPERSISTENT signing selected. This does not configure a stable update identity.')
            return
        config = args.directory.expanduser().resolve() / 'signing-config.json'
        if args.action == 'create':
            config = create_identity(args.directory, args.keytool)
        if args.action == 'upload':
            upload_config(config, args.repo, args.keytool)
        else:
            report = select_signing(json.loads(config.read_text()), args.keytool)
            print(json.dumps(report, indent=2))
            print(f'Private configuration (do not upload as an artifact): {config}')
    except ValueError as error:
        # Validation messages are fixed text and never include credential values.
        raise SystemExit(str(error))
    except OSError:
        # Do not reflect file content, command output or argument values.
        raise SystemExit('Cannot access private signing configuration or required tools; existing identities are never replaced.')


if __name__ == '__main__':
    main()
