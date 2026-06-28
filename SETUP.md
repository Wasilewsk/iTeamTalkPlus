# iTeamTalkPlus

iOS port of TeamTalkPlus with 12-tab interface built on BearWare's iTeamTalk.

## How to Build (Done Automatically by GitHub Actions)

1. Push to `main` — the workflow automatically:
   - Downloads the TeamTalk 5 SDK trial from BearWare
   - Extracts `libTeamTalk5.a`
   - Builds an unsigned `.ipa`
   - Uploads it as a build artifact

2. Download the IPA from GitHub → Actions → workflow run → Artifacts

3. Sign with AltStore on your iOS device:
   - Open AltStore → My Apps → + → select IPA
   - Enter Apple ID
   - AltStore signs and installs

## Note on Trial SDK
The workflow uses the 30-day trial SDK from BearWare. After 30 days:
- The app will stop connecting to servers
- Purchase a license at https://bearware.dk/?page_id=316
- Set `REGISTRATION_NAME` and `REGISTRATION_KEY` in `iTeamTalk/License.swift`

## Manual Build (Mac Only)
1. Run the workflow or follow these steps locally:
   - Download SDK from https://bearware.dk/?page_id=419
   - Place `libTeamTalk5.a` in `Library/TeamTalk_DLL/`
   - Open `iTeamTalk.xcodeproj` in Xcode
   - Set your signing team
   - Build and run
