"""Regression checks for accepting invalid APK manifests."""
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location("verify_apk", Path(__file__).resolve().parents[1] / "tools/verify_apk.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
BADGING = "package: name='org.chainreact.onetappuzzle'\nsdkVersion:'24'\ntargetSdkVersion:'36'\nnative-code: 'arm64-v8a'\n"
MANIFEST = "A: android:screenOrientation(0x101001e)=(type 0x10)0x1\nA: android:debuggable(0x101000f)=(type 0x12)0xffffffff\n"

class ManifestTests(unittest.TestCase):
    def test_valid(self):
        self.assertEqual(module.validate_manifest(BADGING, MANIFEST, ""), [])
    def test_landscape_with_unrelated_one(self):
        with self.assertRaises(AssertionError):
            module.validate_manifest(BADGING, MANIFEST.replace('0x10)0x1', '0x10)0x0') + 'other=(type 0x10)0x1\n', '')
    def test_debug_explicit_false(self):
        with self.assertRaises(AssertionError):
            module.validate_manifest(BADGING, MANIFEST.replace('0xffffffff', '0x0'), '')
    def test_permission_rejected(self):
        with self.assertRaises(AssertionError):
            module.validate_manifest(BADGING, MANIFEST, "uses-permission: name='android.permission.INTERNET'")
    def test_wrong_package(self):
        with self.assertRaises(AssertionError):
            module.validate_manifest(BADGING.replace('org.chainreact.onetappuzzle', 'wrong.package'), MANIFEST, '')

class SignatureTests(unittest.TestCase):
    def test_certificate_fingerprint_is_recorded_and_checked(self):
        self.assertTrue(hasattr(module, 'validate_certificate'), 'Certificate identity must be verified')
        fingerprint = 'ab' * 32
        signature = 'Signer #1 certificate SHA-256 digest: ' + fingerprint + '\n'
        self.assertEqual(module.validate_certificate(signature, fingerprint.upper()), fingerprint)
        with self.assertRaises(AssertionError):
            module.validate_certificate(signature, 'cd' * 32)

    def test_missing_or_multiple_signers_rejected(self):
        self.assertTrue(hasattr(module, 'validate_certificate'), 'Certificate identity must be verified')
        with self.assertRaises(AssertionError):
            module.validate_certificate('Verified using v2 scheme: true', None)
        with self.assertRaises(AssertionError):
            module.validate_certificate('Signer #1 certificate SHA-256 digest: ' + 'ab' * 32 +
                                        '\nSigner #2 certificate SHA-256 digest: ' + 'cd' * 32, None)

if __name__ == '__main__':
    unittest.main()
