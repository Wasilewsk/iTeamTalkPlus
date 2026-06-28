# iTeamTalkPlus-iOS Project Structure

# Setup Phase 1-3: TeamTalkKit Integration & Core Framework

## Project Overview

This document outlines the step-by-step implementation plan for migrating TeamTalkPlus features to iOS with TeamTalkKit integration, leading to a complete iTeamTalkPlus application.

## Phase 1: TeamTalkKit Integration (Days 1-7)

### 1.1 Add TeamTalkKit Framework

#### Option A: Swift Package Manager (SPM)

Add TeamTalkKit to your Xcode project using Swift Package Manager:

```bash
// Package.swift
import PackageDescription

let package = Package(
    name: "iTeamTalkPlus",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "iTeamTalkPlus",
            targets: ["iTeamTalkPlus"]
        )
    ],
    targets: [
        .target(
            name: "iTeamTalkPlus",
            dependencies: [
                .product(name: "TeamTalkKit", package: "TeamTalkKit"),
                .product(name: "TeamTalkC", package: "TeamTalkKit")
            ]
        ),
        .package(
            url: "https://github.com/BearWare/TeamTalk5.git",
            from: "5.24.0"
        ).byName("TeamTalkKit")
    ]
)
```

#### Option B: Local Framework Copy

If you prefer to include TeamTalkKit locally:

1. **Copy TeamTalkKit from BearWare TeamTalk5:**
   - Navigate to `TeamTalk5/Client/iTeamTalk/TeamTalkKit`
   - Copy the entire directory to your project

2. **Project Structure:**
   ```
   iTeamTalkPlus.xcodeproj/
   ├── iTeamTalkPlus/                     // Your app source
   ├── TeamTalkKit/                      // BearWare TeamTalkKit (copied)
   ├── TeamTalkC/                        // BearWare native C library
   └── xcworkspace/                      // Xcode workspace
   ```

### 1.2 Configuration Files

#### Config.xcconfig (Project Settings)
```xcconfig
// iTeamTalkPlus Configuration
INCLUDEPATH = $(PROJECT_DIR)/TeamTalkKit/include
FRAMEWORK_SEARCH_PATHS = $(PROJECT_DIR)/TeamTalkKit
CLANG_CXX_LANGUAGE_STANDARD = c++17
CLANG_CXX_LIBRARY_STANDARD = libc++
SWIFT_COMPILERSPEC_PATH = $(PROJECT_DIR)/Package.swift
PRODUCT_BUNDLE_IDENTIFIER = com.bearware.iteamtalkplus
TARGETED_DEVICE_FAMILY = 1,2
SUPPORTS_IPHONE_OS = YES
```

#### Info.plist (Required Fields)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSExceptionDomains</key>
        <dict>
            <key>bearware.dk</key>
            <dict>
                <key>NSExceptionAllowsInsecureHTTPLoads</key>
                <true/>
            </dict>
        </dict>
    </dict>
</dict>
</plist>
```

## Phase 2: Framework Integration Setup (Days 8-14)

### 2.1 TeamTalkKit Bridging Module

Create a bridging module to simplify TeamTalkKit usage:

#### FrameworkWrapper.swift
```swift
// iTeamTalkPlus/Classes/FrameworkWrapper.swift
import Foundation
import TeamTalkKit
import TeamTalkC

class FrameworkWrapper: ObservableObject {
    static let shared = FrameworkWrapper()
    
    // MARK: - TeamTalk Connection Management
    private var ttClient: TeamTalkClient {
        TeamTalkClient.shared
    }
    
    // MARK: - Observables
    @Published var connectionState: ConnectionState = .disconnected
    @Published var currentUser: User?
    @Published var servers: [Server] = []
    @Published var channels: [Channel] = []
    @Published var messages: [Message] = []
    
    enum ConnectionState {
        case disconnected
        case connecting
        case connected
        case error(String)
    }
    
    // MARK: - Connection Management
    func connect(to server: Server, completion: @escaping (Bool, String?) -> Void) {
        connectionState = .connecting
        
        let ttServer = TeamTalk.Server()
        ttServer.nServerIP = server.ipAddress
        ttServer.nServerPort = Int32(server.port)
        ttServer.nTimeout = 5000
        ttServer.nUdpTimeout = 5000
        ttServer.nTcpTimeout = 5000
        ttServer.nChannelMaxUsers = 200
        ttServer.nMaxLogins = 0
        ttServer.nFileUploadPort = 0
        ttServer.nFileDownloadPort = 0
        
        if let username = TeamTalkString.setUser(.username, to: server.username),
           let password = TeamTalkString.setUser(.password, to: server.password) {
            
            ttServer.nUserRight = SERVER_RIGHT_ALL
            
            ttClient.connect(to: ttServer) { result in
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        self.connectionState = .connected
                        completion(true, nil)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.connectionState = .error(error.localizedDescription)
                        completion(false, error.localizedDescription)
                    }
                }
            }
        } else {
            connectionState = .error("Invalid user credentials")
            completion(false, "Invalid user credentials")
        }
    }
    
    // MARK: - Message Handling
    func setupMessageHandling() {
        TeamTalkClient.shared.addMessageObserver(self)
    }
    
    // MARK: - Audio Control
    func setEchoCancellation(_ enabled: Bool) {
        let result = TeamTalkAudioCodec.enableEchoCancellation(enabled)
        print("Echo Cancellation: \(enabled) - Success: \(result)")
    }
    
    func setNoiseSuppression(_ enabled: Bool) {
        let result = TeamTalkAudioCodec.enableNoiseSuppression(enabled)
        print("Noise Suppression: \(enabled) - Success: \(result)")
    }
    
    func setAutoGainControl(_ enabled: Bool) {
        let result = TeamTalkAudioCodec.enableAutomaticGainControl(enabled)
        print("Auto Gain Control: \(enabled) - Success: \(result)")
    }
}

extension FrameworkWrapper: TeamTalkMessageObserver {
    func handleTeamTalkMessage(_ message: TTMessage) {
        DispatchQueue.main.async {
            switch message.messageType {
            case .TT_MESSAGE_TYPE_USER:\n                if let textMsg = message.textMessage {\n                    let user = try? User(from: textMsg.user)\n                    self.currentUser = user\n                }\n            case .TT_MESSAGE_TYPE_CHANNEL:\n                if let channelMsg = message.channelMessage {\n                    let channel = try? Channel(from: channelMsg.channel)\n                    if let channel = channel {\n                        if !self.channels.contains(where: { $0.id == channel.id }) {\n                            self.channels.append(channel)\n                        } else {\n                            // Update existing channel\n                            if let index = self.channels.firstIndex(where: { $0.id == channel.id }) {\n                                self.channels[index] = channel\n                            }\n                        }\n                    }\n                }\n            default:\n                break\n            }\n        }\n    }\n}
```

## Phase 3: 12-Tab Dashboard Implementation (Days 15-30)

### 3.1 Project Structure for iOS

```
iTeamTalkPlus.xcodeproj/
├── iTeamTalkPlus/
│   ├── ViewModels/                    // SwiftUI ViewModels
│   │   ├── MainViewModel.swift        // Main coordination
│   │   ├── ServerViewModel.swift       // Server management
│   │   ├── ChannelViewModel.swift      // Channel management
│   │   ├── ChatViewModel.swift         // Chat functions\n │   │   ├── UserViewModel.swift        // User management\n │   │   ├── AudioViewModel.swift        // Audio controls\n │   │   └── SettingsViewModel.swift     // App settings\n │   ├── Views/                       // SwiftUI Views\n │   │   ├── MainTabView.swift          // 12-tab interface\n │   │   ├── ChannelListView.swift      // Page 2: Channels\n │   │   ├── ServerManagementView.swift // Page 4: Server admin\n │   │   ├── AudioControlView.swift     // Page 8: Audio settings\n │   │   └── ... (9 more views) \n │   ├── Models/                       // Data models\n │   │   ├── Server.swift               // Server model\n │   │   ├── Channel.swift              // Channel model\n │   │   ├── Message.swift              // Message model\n │   │   └── User.swift                // User model\n │   ├── Services/                   // Network and business logic\n │   │   ├── NetworkService.swift      // HTTP/Network requests\n │   │   ├── AuthenticationService.swift // Login/Auth\n │   │   └── TeamTalkService.swift      // Core TeamTalk integration\n │   └── Utils/                       // Helper functions\n │       ├── AccessibilityUtils.swift   // VoiceOver support\n │       ├── AudioUtils.swift           // Audio processing utilities\n │       ├── TextUtils.swift            // Text formatting utilities\n │       └── PreferencesUtils.swift      // User preferences\n └── Resources/                      // Assets and strings\n     ├── Assets.xcassets\n     └── Localizable.strings\n```

### 3.2 MainTabView.swift (12-Tab Interface)

```swift
// iTeamTalkPlus/Views/MainTabView.swift
import SwiftUI

struct MainTabView: View {\n    @StateObject private var mainViewModel = MainViewModel()\n    \n    var body: some View {\n        TabView {\n            // Tab 1: Files (Page 1)\n            FileManagementView()\n                .tabItem {\n                    Label(\"Files\", systemImage: \"folder\" )\n                }\n                .tag(1)\n            \n            // Tab 2: Channels (Page 2)\n            ChannelListView()\n                .tabItem {\n                    Label(\"Channels\", systemImage: \"list.bullet\" )\n                }\n                .tag(2)\n            \n            // Tab 3: Media Streams (Page 3)\n            MediaStreamingView()\n                .tabItem {\n                    Label(\"Media\", systemImage: \"speaker.wave.2\" )\n                }\n                .tag(3)\n            \n            // Tab 4: Server Management (Page 4)\n            ServerManagementView()\n                .tabItem {\n                    Label(\"Server\", systemImage: \"gear\" )\n                }\n                .tag(4)\n            \n            // Tab 5: Global Chat (Page 5)\n            GlobalChatView()\n                .tabItem {\n                    Label(\"Global\", systemImage: \"GLOBE\" )\n                }\n                .tag(5)\n            \n            // Tab 6: Event History (Page 6)\n            EventHistoryView()\n                .tabItem {\n                    Label(\"Events\", systemImage: \"clock\" )\n                }\n                .tag(6)\n            \n            // Tab 7: Channel Messages (Page 7)\n            ChannelMessagesView()\n                .tabItem {\n                    Label(\"Messages\", systemImage: \"message\" )\n                }\n                .tag(7)\n            \n            // Tab 8: Settings (Page 8)\n            PreferencesView()\n                .tabItem {\n                    Label(\"Settings\", systemImage: \"slider.horizontal.3\" )\n                }\n                .tag(8)\n            \n            // Tab 9: Private Messages (Page 9)\n            PrivateMessagesView()\n                .tabItem {\n                    Label(\"Private\", systemImage: \"bubble.left.and.bubble.right\" )\n                }\n                .tag(9)\n            \n            // Tab 10: Connection Status (Page 10)\n            ConnectionStatusView()\n                .tabItem {\n                    Label(\"Status\", systemImage: \"Network\" )\n                }\n                .tag(10)\n            \n            // Tab 11: Online Users (Page 11)\n            OnlineUsersView()\n                .tabItem {\n                    Label(\"Users\", systemImage: \"person.2\" )\n                }\n                .tag(11)\n            \n            // Tab 12: Manage Status (Page 12)\n            ManageStatusView()\n                .tabItem {\n                    Label(\"Status\", systemImage: \"person.crop.circle\" )\n                }\n                .tag(12)\n        }\n        .accentColor(.blue)\n        .onAppear {\n            mainViewModel.loadInitialData()\n        }\n    }\n}
```

### 3.3 ChannelListView.swift (Page 2: Channels)

```swift
// iTeamTalkPlus/Views/ChannelListView.swift
import SwiftUI

struct ChannelListView: View {\n    @StateObject private var channelViewModel = ChannelViewModel()\n    @State private var showServerConnection = false\n    @State private var serverInput = \"\"\n    @State private var usernameInput = \"\"\n    @State private var passwordInput = \"\"\n    @State private var showJoinChannelDialog = false\n    @State private var selectedChannel: Channel? = nil\n    \n    var body: some View {\n        NavigationView {\n            VStack {\n                // Connection Status Bar\n                ConnectionStatusBar(viewModel: channelViewModel)\n                    .padding()\n                \n                // Server Connection Form (if not connected)\n                if !channelViewModel.isConnected {\n                    VStack {\n                        Text(\"Server Connection\")\n                            .font(.headline)\n                        \n                        TextField(\"Server URL (bearware.dk) \", text: $serverInput)\n                            .textFieldStyle(RoundedBorderTextFieldStyle())\n                            .padding()\n                        \n                        TextField(\"Username\", text: $usernameInput)\n                            .textFieldStyle(RoundedBorderTextFieldStyle())\n                            .padding()\n                        \n                        SecureField(\"Password\", text: $passwordInput)\n                            .textFieldStyle(RoundedBorderTextFieldStyle())\n                            .padding()\n                        \n                        Button(action: {\n                            if let url = URL(string: \"https://\\(serverInput)\") {\n                                channelViewModel.connect(to: url, username: usernameInput, password: passwordInput)\n                            }\n                        }) {\n                            Text(\"Connect to Server\")\n                                .frame(maxWidth: .infinity)\n                                .padding()\n                                .background(Color.blue)\n                                .foregroundColor(.white)\n                                .cornerRadius(10)\n                        }\n                        .disabled(serverInput.isEmpty || usernameInput.isEmpty || passwordInput.isEmpty)\n                    }\n                    .padding()\n                    .background(Color.gray.opacity(0.1))\n                    .cornerRadius(10)\n                    .padding()\n                }\n                \n                // Channel List\n                if channelViewModel.isConnected {\n                    List(channelViewModel.channels) { channel in\n                        ChannelRow(channel: channel)\n                            .onTapGesture {\n                                selectedChannel = channel\n                                showJoinChannelDialog = true\n                            }\n                    }\n                } else {\n                    VStack {\n                        Image(systemName: \"wifi.slash\" )\n                            .font(.largeTitle)\n                            .foregroundColor(.gray)\n                        Text(\"Not Connected\")\n                            .font(.headline)\n                            .foregroundColor(.gray)\n                        Text(\"Please connect to a server first\")\n                            .font(.subheadline)\n                            .foregroundColor(.gray)\n                    }\n                    .frame(maxWidth: .infinity, maxHeight: .infinity)\n                }\n            }\n            .navigationTitle(\"Channels\")\n            .navigationBarTitleDisplayMode(.inline)\n            .sheet(isPresented: $showJoinChannelDialog) {\n                if let channel = selectedChannel {\n                    JoinChannelView(channel: channel, viewModel: channelViewModel)\n                }\n            }\n        }\n    }\n}
```

## Phase 4: Feature Implementation (Days 31-90+)

### 4.1 Server Management Features

#### Enhanced Authentication & Server Properties
```swift
// iTeamTalkPlus/Services/ServerManagementService.swift
import Foundation
import TeamTalkKit

class ServerManagementService {\n    private let frameworkWrapper = FrameworkWrapper.shared\n    \n    // MARK: - Server Information Management\n    func getServerInformation() async -> Result<ServerInfo, Error> {\n        do {\n            // TeamTalkKit server information calls\n            let serverInfo = try await frameworkWrapper.getServerInfo()\n            return .success(serverInfo)\n        } catch {\n            return .failure(error)\n        }\n    }\n    \n    func updateServerName(_ name: String, serverID: Int32) async -> Result<Bool, Error> {\n        do {\n            let result = try await frameworkWrapper.updateServerName(name, serverID: serverID)\n            return .success(result)\n        } catch {\n            return .failure(error)\n        }\n    }\n    \n    func updateMOTD(_ motd: String, serverID: Int32) async -> Result<Bool, Error> {\n        do {\n            let result = try await frameworkWrapper.updateMOTD(motd, serverID: serverID)\n            return .success(result)\n        } catch {\n            return .failure(error)\n        }\n    }\n    \n    // MARK: - User Account Management\n    func getUserAccounts() async -> Result<[UserAccount], Error> {\n        do {\n            let users = try await frameworkWrapper.getUsers()\n            let accounts = users.map { UserAccount(from: $0) }\n            return .success(accounts)\n        } catch {\n            return .failure(error)\n        }\n    }\n    \n    func createUserAccount(_ account: UserAccount) async -> Result<Bool, Error> {\n        do {\n            let result = try await frameworkWrapper.createUser(account)\n            return .success(result)\n        } catch {\n            return .failure(error)\n        }\n    }\n    \n    func deleteUserAccount(_ userID: Int32) async -> Result<Bool, Error> {\n        do {\n            let result = try await frameworkWrapper.deleteUser(userID)\n            return .success(result)\n        } catch {\n            return .failure(error)\n        }\n    }\n    \n    // MARK: - Advanced Ban Management\n    func getBannedUsers() async -> Result<[BanRecord], Error> {\n        do {\n            let bans = try await frameworkWrapper.getBans()\n            return .success(bans)\n        } catch {\n            return .failure(error)\n        }\n    }\n    \n    func banUserByIP(_ ipAddress: String, channelID: Int32, duration: Int, reason: String) async -> Result<Bool, Error> {\n        do {\n            let result = try await frameworkWrapper.banUser(byIP: ipAddress, channelID: channelID, duration: duration, reason: reason)\n            return .success(result)\n        } catch {\n            return .failure(error)\n        }\n    }\n    \n    func banUserByName(_ username: String, channelID: Int32, duration: Int, reason: String) async -> Result<Bool, Error> {\n        do {\n            let result = try await frameworkWrapper.banUser(byName: username, channelID: channelID, duration: duration, reason: reason)\n            return .success(result)\n        } catch {\n            return .failure(error)\n        }\n    }\n    \n    func kickUserFromChannel(_ userID: Int32, channelID: Int32, reason: String) async -> Result<Bool, Error> {\n        do {\n            let result = try await frameworkWrapper.kickUser(userID, channelID: channelID, reason: reason)\n            return .success(result)\n        } catch {\n            return .failure(error)\n        }\n    }\n    \n    // MARK: - Channel Management\n    func createChannel(_ channel: Channel, password: String) async -> Result<Bool, Error> {\n        do {\n            let result = try await frameworkWrapper.createChannel(channel, password: password)\n            return .success(result)\n        } catch {\n            return .failure(error)\n        }\n    }\n    \n    func getChannelUsers(_ channelID: Int32) async -> Result<[User], Error> {\n        do {\n            let users = try await frameworkWrapper.getChannelUsers(channelID)\n            return .success(users)\n        } catch {\n            return .failure(error)\n        }\n    }\n    \n    func moveUserToChannel(_ userID: Int32, fromChannel: Int32, toChannel: Int32) async -> Result<Bool, Error> {\n        do {\n            let result = try await frameworkWrapper.moveUser(userID, fromChannel: fromChannel, toChannel: toChannel)\n            return .success(result)\n        } catch {\n            return .failure(error)\n        }\n    }\n}
```

## Phase 5: Audio Engineering Implementation (Days 91-120)

### 5.1 Advanced Audio Processing

```swift
// iTeamTalkPlus/Services/AudioProcessingService.swift
import Foundation
import TeamTalkKit

class AudioProcessingService: ObservableObject {\n    @Published var isAECEnabled = false\n    @Published var isNSEnabled = false\n    @Published var isAGCEna\cled = false\n    @Published var currentGain: Float = 50.0\n    @Published var availableCodecs: [AudioCodec] = []\n    @Published var selectedCodec: AudioCodec? = nil\n    \n    private let frameworkWrapper = FrameworkWrapper.shared\n    \n    init() {\n        loadAvailableCodecs()\n        loadUserPreferences()\n    }\n    \n    // MARK: - Voice Processing Control\n    func configureVoiceProcessing(aec: Bool, ns: Bool, agc: Bool, gain: Float) {\n        frameworkWrapper.setEchoCancellation(aec)\n        frameworkWrapper.setNoiseSuppression(ns)\n        frameworkWrapper.setAutoGainControl(agc)\n        // TODO: Implement native gain control\n        \n        // Save user preferences\n        PreferencesUtils.echoCancellationEnabled = aec\n        PreferencesUtils.noiseSuppressionEnabled = ns\n        PreferencesUtils.autoGainControlEnabled = agc\n        PreferencesUtils.microphoneGain = gain\n    }\n    \n    func loadDefaultAudioSettings() {\n        isAECEnabled = PreferencesUtils.echoCancellationEnabled\n        isNSEnabled = PreferencesUtils.noiseSuppressionEnabled\n        isAGCEna\cled = PreferencesUtils.autoGainControlEnabled\n        currentGain = PreferencesUtils.microphoneGain\n    }\n    \n    // MARK: - Audio Codec Management\n    func loadAvailableCodecs() {\n        availableCodecs = [\n            AudioCodec(id: 0, name: \"Opus\", bitrate: 32000, sampleRate: 48000),\n            AudioCodec(id: 1, name: \"Speex\", bitrate: 16000, sampleRate: 8000),\n            AudioCodec(id: 2, name: \"Speex VBR\", bitrate: -1, sampleRate: 8000)\n        ]\n        \n        selectedCodec = availableCodecs.first\n    }\n    \n    // MARK: - Audio Device Management\n    func getAvailableAudioDevices() async -> Result<[AudioDevice], Error> {\n        do {\n            let devices = try await frameworkWrapper.getAudioDevices()\n            return .success(devices)\n        } catch {\n            return .failure(error)\n        }\n    }\n    \n    // MARK: - Advanced Audio Settings\n    func getAdvancedAudioSettings() async -> Result<AdvancedAudioSettings, Error> {\n        do {\n            let settings = try await frameworkWrapper.getAudioSettings()\n            return .success(settings)\n        } catch {\n            return .failure(error)\n        }\n    }\n}\n\n// MARK: - Supporting Types\n\nstruct AudioCodec {\n    let id: Int32\n    let name: String\n    let bitrate: Int32\n    let sampleRate: Int32\n    let description: String\n    \n    init(id: Int32, name: String, bitrate: Int32, sampleRate: Int32, description: String = \"\") {\n        self.id = id\n        self.name = name\n        self.bitrate = bitrate\n        self.sampleRate = sampleRate\n        self.description = description\n    }\n}\n\nstruct AudioDevice {\n    let id: Int32\n    let name: String\n    let type: DeviceType\n    let isDefault: Bool\n    \n    enum DeviceType {\n        case microphone, speaker, headset, bluetooth\n    }\n}\n\nstruct AdvancedAudioSettings {\n    let aecEnabled: Bool\n    let aecDelay: Int32\n    let nsEnabled: Bool\n    let nsLevel: Int32\n    let agcEnabled: Bool\n    let agcGain: Int32\n    let automaticGainControl: Bool\n    let compressionEnabled: Bool\n}\n```

## Phase 6: GitHub Actions Integration (Days 1-7)

### 6.1 CI/CD Pipeline Configuration

Create `.github/workflows/build.yml`:

```yaml
name: Build & Test iTeamTalkPlus-iOS
\noon:\n    push:\n        branches: [ main ]\n    pull_request:\n        branches: [ main ]\n    release:\n        types: [ created ]\n\njobs:\n    build:\n        runs-on: macos-latest\n        strategy:\n            matrix:\n                xcode: [\"14.2\", \"15.0\"]\n        steps:\n            - name: Checkout code\n                uses: actions/checkout@v4\n            \n            - name: Set Xcode version\n                run: sudo xcode-select -s /Applications/Xcode_${{ matrix.xcode }}.app/Contents/Developer\n            \n            - name: Install dependencies\n                run: brew install swiftlint carthage\n            \n            - name: Build iTeamTalkPlus-iOS\n                run: |\n                    xcodebuild clean build \
                        -workspace iTeamTalkPlus.xcodeproj/xcworkspace \
                        -scheme iTeamTalkPlus \
                        -configuration Release \
                        -destination generic/platform=iOS\n            \n            - name: Run tests\n                run: |\n                    xcodebuild test \
                        -workspace iTeamTalkPlus.xcodeproj/xcworkspace \
                        -scheme iTeamTalkPlus \
                        -configuration Debug \
                        -destination generic/platform=iOS/Simulator,name=iPhone 14\n            \n            - name: Run SwiftLint\n                run: swiftlint lint --path Sources --strict\n            \n            - name: Format code\n                run: swiftformat Sources Tests\n            \n            - name: Build IPA\n                run: |\n                    mkdir -p build/ipa\n                    xcodebuild archive \
                        -workspace iTeamTalkPlus.xcodeproj/xcworkspace \
                        -scheme iTeamTalkPlus \
                        -configuration Release \
                        -archivePath build/iTeamTalkPlus \
                        -destination generic/platform=iOS\n                    \n                    xcodebuild -exportArchive \
                        -archivePath build/iTeamTalkPlus.xcarchive \
                        -exportPath build/ipa \
                        -exportOptionsPlist export-options.plist\n            \n            - name: Upload IPA artifact\n                uses: actions/upload-artifact@v4\n                with:\n                    name: iTeamTalkPlus-${{ github.run_number }}\n                    path: build/ipa/iTeamTalkPlus.ipa\n            \n            - name: Create release\n                if: github.event_name == 'release'\n                uses: softprops/action-gh-release@v1\n                with:\n                    files: build/ipa/iTeamTalkPlus.ipa\n                    draft: false\n                    prerelease: false\n```

### 6.2 Xcode Project Configuration

Create `iTeamTalkPlus.xcodeproj/project.pbxproj` template:

```objective-c
// Begin PBXBuildFile section
        // Essential build files for iTeamTalkPlus-iOS
        123456789ABCDEF012345678 /* AppDelegate.swift in Sources */ = {isa = PBXBuildFile; fileRef = 123456789ABCDEF012345679 /* AppDelegate.swift */; };
        123456789ABCDEF012345680 /* SceneDelegate.swift in Sources */ = {isa = PBXBuildFile; fileRef = 123456789ABCDEF012345681 /* SceneDelegate.swift */; };
        123456789ABCDEF012345682 /* iTeamTalkPlus.swift */ = {isa = PBXBuildFile; fileRef = 123456789ABCDEF012345683 /* iTeamTalkPlus.swift */; };
        123456789ABCDEF012345684 /* TeamTalkKit.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 123456789ABCDEF012345685 /* TeamTalkKit.framework */; };
\n// Development frameworks\n        123456789ABCDEF012345686 /* UIKit.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 123456789ABCDEF012345687 /* UIKit.framework */; };
        123456789ABCDEF012345688 /* SwiftUI.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 123456789ABCDEF012345689 /* SwiftUI.framework */; };
        123456789ABCDEF012345690 /* Combine.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 123456789ABCDEF012345691 /* Combine.framework */; };
\n// End PBXBuildFile section
```

## Implementation Timeline & Milestones

### Week 1-2: Foundation Setup
- [ ] TeamTalkKit integration completed
- [ ] FrameworkWrapper implemented  
- [ ] Core data models established
- [ ] Basic connection management

### Week 3-4: 12-Tab Interface
- [ ] MainTabView with all 12 tabs
- [ ] ChannelListView (Page 2)
- [ ] ServerManagementView (Page 4)
- [ ] AudioControlView (Page 8)

### Week 5-6: Core Features
- [ ] User Account Management
- [ ] Media Streaming implementation
- [ ] File Transfer system
- [ ] Advanced Ban Management

### Week 7-8: Audio & Accessibility
- [ ] Advanced Audio Processing
- [ ] Enhanced Accessibility (TalkBack equivalent)
- [ ] Voice Activity Detection
- [ ] Sound Effects management

### Week 9-10: Advanced Features
- [ ] Event History logging
- [ ] Server Statistics
- [ ] Deep Linking support
- [ ] Preferences and Settings

### Week 11-12: Testing & Optimization
- [ ] Unit test coverage (>80%)
- [ ] UI testing
- [ ] Performance optimization
- [ ] GitHub Actions integration

## Success Criteria

### Technical Requirements
- [ ] Native TeamTalkKit integration with proper Swift bindings
- [ ] Full 12-tab interface implemented
- [ ] All TeamTalkPlus features ported to iOS
- [ ] Advanced audio processing (AEC/NS/AGC) working
- [ ] Enhanced accessibility support
- [ ] Media streaming capabilities
- [ ] Advanced server administration

### Code Quality
- [ ] Swift 5.0+ compatible
- [ ] iOS 14+ minimum support
- [ ] MVVM/MVI architecture
- [ ] Clean code and documentation
- [ ] Comprehensive unit tests

### User Experience
- [ ] Intuitive 12-tab interface
- [ ] TalkBack accessibility equivalent
- [ ] Smooth audio processing controls
- [ ] Server admin dashboard
- [ ] Real-time updates and notifications

## Next Steps for Development

1. **Copy TeamTalkKit Framework:** `
   - Copy from TeamTalk5/Client/iTeamTalk/TeamTalkKit to project root`
2. **Configure SPM Integration:** Setup Package.swift and xcode-project configuration
3. **Implement MainTabView:** Start with Channels view, add remaining tabs progressively
4. **Connect Framework Wrapper:** Implement TeamTalkKit integration methods
5. **Add Core Features:** Server management, audio processing, user accounts
6. **Test & Optimize:** Run GitHub Actions pipeline, iterate on performance

This roadmap provides a comprehensive plan for implementing all TeamTalkPlus features on iOS with TeamTalkKit integration, following best practices and ensuring high-quality results for the iTeamTalkPlus-iOS application.
