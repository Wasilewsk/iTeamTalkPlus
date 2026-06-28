# iTeamTalkPlus

Enhanced iOS TeamTalk 5 client with a 12-tab interface, server administration, file management, media streaming, sound events, and VoiceOver accessibility.

Built on [BearWare](https://bearware.dk)'s [iTeamTalk](https://github.com/BearWare/TeamTalk5/tree/master/Client/iTeamTalk) native Swift/TeamTalkKit architecture.

## Features

- **12-tab dashboard** — Channels, Chat, Global Chat, Private Messages, Media Streams, Files, Server Management, Online Users, Connection Status, Sound Events, My Status, Preferences
- **Server administration** — User accounts, bans, server properties
- **File management** — Upload, download, delete channel files with progress tracking
- **Media streaming** — Stream audio/video files to channels with play/stop controls
- **Sound events** — 14 configurable sound effects for TX, messages, user join/leave, server lost, VOX trigger, etc.
- **Enhanced audio** — AEC, NS, AGC, microphone gain, push-to-talk, voice activation
- **VoiceOver accessibility** — Labels, hints, custom actions across all views
- **19 languages** — Full localization support

## Build with GitHub Actions

The CI workflow auto-downloads the TeamTalk 5 SDK trial (30-day evaluation) and produces an unsigned IPA.

1. Push to `main` — workflow at `.github/workflows/build-and-release.yml`
2. Download the IPA artifact from the Actions run
3. Sign with [AltStore](https://altstore.io) on your iOS device

### Manual Build

Prerequisites: Xcode 16+, TeamTalk 5 SDK (`Library/TeamTalk_DLL/libTeamTalk5.a`)

```bash
xcodebuild -project iTeamTalk.xcodeproj -scheme iTeamTalk -configuration Release \
  -destination "generic/platform=iOS" \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

## Configuration

| Setting | Location | Value |
|---|---|---|
| SDK client name | `iTeamTalk/AppInfo.swift` | `teamtalkpluss_for-ios` |
| App version | `iTeamTalk.xcodeproj` `MARKETING_VERSION` | `1.0` |
| Bundle ID | `iTeamTalk.xcodeproj` `PRODUCT_BUNDLE_IDENTIFIER` | `com.bearware.iteamtalkplus` |
| License (30-day trial) | `iTeamTalk/License.swift` | Empty strings |
| Production license | `iTeamTalk/License.swift` | Set `REGISTRATION_NAME`/`REGISTRATION_KEY` after purchase |

## License

Requires a [TeamTalk 5 SDK License](https://bearware.dk/?page_id=393) from BearWare.dk for production use. The 30-day trial SDK is auto-downloaded by CI.

## Credits

- [BearWare.dk](https://bearware.dk) — TeamTalk 5 SDK and original iTeamTalk iOS client
- [AltStore](https://altstore.io) — Side-loading unsigned IPAs
