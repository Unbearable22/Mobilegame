# Android debug signing

The application ID stays `org.chainreact.onetappuzzle`. All APKs from this workflow are **debug APKs**, built with Godot 4.7.2, JDK 17 and ARM64 only. These credentials are for debug distribution, never release signing.

## Current configuration and required owner action

On 2026-11-12, the connected GitHub integration reported repository `ADMIN` access but returned **HTTP 403: Resource not accessible by integration** for both Actions Secrets inventory and the repository encryption public key. The upload helper was attempted and stopped before writing any Secret. No configured Secret names could be read back. Stable CI signing is therefore **pending owner setup**, not claimed complete.

A durable local identity was created in `/home/codespace/.local/share/chain-react-signing/`, outside Git and build artifacts. The directory is mode 700; its keystore and `signing-config.json` are mode 600. Its public certificate SHA-256 is:

```text
3ff232e70e87f245e1e400f4ba31853f64b2c60b7d5d88b6e14a2b42cadae384
```

The owner must back up that directory securely and upload the same identity using a GitHub login/token allowed to read and write repository Actions Secrets. A workspace can be deleted; its local key is not a remote backup. From this workspace, with authorized `gh` credentials:

```bash
python3 tools/setup_debug_signing.py inspect
python3 tools/setup_debug_signing.py upload --repo Unbearable22/Mobilegame
gh secret list --repo Unbearable22/Mobilegame --json name
```

The helper uses stdin for Secret values and environment password sources for `keytool`; it prints only names and public certificate metadata. It refuses to overwrite any existing signing Secrets. If setup was partially completed, an owner must reconcile the existing names with the backed-up identity before proceeding; do not rotate/delete Secrets to bypass this guard.

Required **repository Actions Secrets**:

| Secret | Contents |
| --- | --- |
| `ANDROID_DEBUG_KEYSTORE_BASE64` | Base64 of the complete durable debug keystore |
| `ANDROID_DEBUG_KEY_ALIAS` | Private key entry alias |
| `ANDROID_DEBUG_STORE_PASSWORD` | Keystore password |
| `ANDROID_DEBUG_KEY_PASSWORD` | Private key entry password |

For another trusted machine, securely transfer the directory, update the keystore path in its private configuration, and use `--directory /private/path` with the helper. If the key has truly never been created, `python3 tools/setup_debug_signing.py create` creates it once at the default location. An existing directory, including a partial setup, is never replaced. Do not create another identity while this one is available. Neither the JSON nor the keystore belongs in Git, a Page, workflow logs, or an uploaded artifact.

After setting Secrets, run a normal workflow and check that the artifact is named `chain-react-debug-arm64-persistent-debug-…`, `signing-mode.json` reports `persistent: true`, and its certificate digest matches the backed-up certificate. Run it again and compare the **certificate** digests; APK SHA-256 values may legitimately differ. Secret-name readback alone does not prove a successful build or a matching certificate.

## Default failure and explicit temporary APKs

Push, pull-request and default manual runs fail when Secrets are absent, blank, partial, malformed, or invalid. There is no automatic generation and no signing-key cache fallback. Fork pull requests do not receive Secrets and therefore cannot produce a signed APK by default.

For an explicitly requested test artifact while owner setup is pending:

```bash
gh workflow run android-debug.yml --ref feat/chain-react-mvp \
  -f allow_ephemeral_signing=true
```

Only `workflow_dispatch` with that boolean enabled may generate a fresh temporary identity, and only when **all** signing Secrets are absent. Partial or invalid configuration always fails. Logs warn, the artifact name contains `EPHEMERAL-NONPERSISTENT`, and public reports state `ephemeral-nonpersistent`, `persistent: false`, and the actual certificate digest. The temporary key is cleaned up and never uploaded. This produces a test APK; it does **not** finish stable CI signing setup or establish an identity for future updates. If stable Secrets are present, even an opted-in manual run uses them.

## Local builds and credential handling

Use the existing private JSON with the normal build command:

```bash
python3 tools/build_android.py \
  --godot /path/to/Godot_v4.7.2-stable_linux.x86_64 \
  --sdk /path/to/android-sdk --java /path/to/jdk-17 \
  --templates /path/to/templates \
  --signing-config "$HOME/.local/share/chain-react-signing/signing-config.json"
```

Alternatively set all four `CHAIN_REACT_SIGNING_KEYSTORE`, `CHAIN_REACT_SIGNING_ALIAS`, `CHAIN_REACT_SIGNING_STORE_PASSWORD`, and `CHAIN_REACT_SIGNING_KEY_PASSWORD` environment variables from secure local storage. The key must be outside the repository and owner-only. There is no implicit local default. `--allow-ephemeral-signing` explicitly opts into a temporary identity when no signing variables are set.

Godot receives a placeholder password. An isolated Java SDK wrapper supplies the real password to Godot’s `keytool` preflight through `-storepass:env`; an Android SDK wrapper supplies the real keystore and key passwords to Android `apksigner` through its `env:` inputs, avoiding passwords in command arguments and logs. The selected private key is validated before export. The finished APK certificate is verified against that selected identity; the artifact contains only its public digest and signing mode. Upload is restricted to `build/android/`; private configuration lives outside it.

## Existing v0.5.0 installs

The earlier workflow generated its debug identity on each fresh runner. Its private key was not retained in this repository and cannot be recovered from the APK. A new durable identity cannot be promised to update an installation signed by that old certificate. Android requires matching signing identities for an in-place update, regardless of an unchanged package ID. Back up the complete `progress.json` before reinstalling, following [Android progress transfer](android-progress-transfer.md). Statistics export is not a progress/settings backup; uninstalling removes app-local saves. Future APKs signed with the configured durable identity can retain their update identity.

No release key or release signing workflow is introduced. Physical-device upgrade compatibility remains unverified until tested on a device.

## Local v0.5.1 verification

A real Godot 4.7.2 export from the isolated v0.5.1 source passed with JDK 17 and the durable debug identity after adding the Java SDK preflight wrapper. APK verification confirmed the unchanged package ID, ARM64, debug flag, 50 packaged levels, no requested permissions, 16 KiB alignment and packaged-resource smoke. The build log was checked programmatically for both private passwords; neither was present. APK SHA-256: `cb139f6d91a6b3f2e34b2b91d5d7d6eda91910785e5049e91dc88ae64e426415`. This establishes local export behavior; owner-managed GitHub Secrets setup remains pending.
