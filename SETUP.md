# Setup Guide for iTeamTalkPlus Build

## What You Need

### 1. TeamTalk SDK License (Required)
Purchase from https://www.bearware.dk
- Request the **iOS** SDK (`libTeamTalk5.a`)
- You'll receive: `libTeamTalk5.a`, `REGISTRATION_NAME`, `REGISTRATION_KEY`

### 2. GitHub Secrets Configuration
Go to: https://github.com/Wasilewsk/iTeamTalkPlus/settings/secrets/actions

Add these secrets:

| Secret | Value |
|--------|-------|
| `TEAMTALK_SDK_BASE64` | Base64-encoded `libTeamTalk5.a` |
| `REGISTRATION_NAME` | Your BearWare SDK license name |
| `REGISTRATION_KEY` | Your BearWare SDK license key |

To encode the SDK binary:
```bash
base64 -i libTeamTalk5.a | pbcopy
```
Then paste as the `TEAMTALK_SDK_BASE64` secret.

### 3. Trigger a Build
Push to `main` or create a version tag:
```bash
git tag v1.0.0
git push origin v1.0.0
```

Or manually trigger: GitHub → Actions → "Build and Release" → "Run workflow"

### 4. Download the IPA
After the workflow completes:
1. Go to the Actions page
2. Click the completed workflow run
3. Download the `iTeamTalkPlus-<number>` artifact

### 5. Sign with AltStore
1. Transfer the IPA to your iOS device (AirDrop, Files, etc.)
2. Open AltStore on your iOS device
3. Tap "My Apps" → "+" → select the IPA
4. Enter your Apple ID
5. AltStore will sign and install

## Local Development (Mac Only)

1. Place `libTeamTalk5.a` in `Library/TeamTalk_DLL/`
2. Set `REGISTRATION_NAME` and `REGISTRATION_KEY` in `iTeamTalk/License.swift`
3. Open `iTeamTalk.xcodeproj` in Xcode
4. Set your signing team in Signing & Capabilities
5. Build and run
