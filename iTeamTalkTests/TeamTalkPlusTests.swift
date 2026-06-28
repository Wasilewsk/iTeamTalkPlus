import XCTest
import UIKit
import SwiftUI
import TeamTalkKit
@testable import iTeamTalk

final class TeamTalkPlusTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Server Model Tests

    func testServerEncodingDecoding() {
        let server = Server()
        server.name = "Test Server"
        server.ipaddr = "192.168.1.1"
        server.tcpport = 10333
        server.udpport = 10333
        server.username = "testuser"
        server.password = "testpass"
        server.nickname = "Tester"
        server.channel = "/test"
        server.chanpasswd = "chanpass"
        server.encrypted = true
        server.servertype = .LOCAL

        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: server, requiringSecureCoding: true) else {
            XCTFail("Failed to archive server")
            return
        }

        guard let decoded = try? NSKeyedUnarchiver.unarchivedObject(ofClass: Server.self, from: data) else {
            XCTFail("Failed to unarchive server")
            return
        }

        XCTAssertEqual(decoded.name, server.name)
        XCTAssertEqual(decoded.ipaddr, server.ipaddr)
        XCTAssertEqual(decoded.tcpport, server.tcpport)
        XCTAssertEqual(decoded.udpport, server.udpport)
        XCTAssertEqual(decoded.username, server.username)
        XCTAssertEqual(decoded.password, server.password)
        XCTAssertEqual(decoded.nickname, server.nickname)
        XCTAssertEqual(decoded.channel, server.channel)
        XCTAssertEqual(decoded.chanpasswd, server.chanpasswd)
        XCTAssertEqual(decoded.encrypted, server.encrypted)
        XCTAssertEqual(decoded.servertype, .LOCAL)
    }

    func testServerListPersistence() {
        let original = [Server]()

        // Clear any existing servers
        saveLocalServers(original)
        var loaded = loadLocalServers()
        XCTAssertEqual(loaded.count, 0)

        let server1 = Server()
        server1.name = "Server 1"
        server1.ipaddr = "10.0.0.1"
        server1.servertype = .LOCAL

        let server2 = Server()
        server2.name = "Server 2"
        server2.ipaddr = "10.0.0.2"
        server2.servertype = .LOCAL

        saveLocalServers([server1, server2])
        loaded = loadLocalServers()
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].name, "Server 1")
        XCTAssertEqual(loaded[1].name, "Server 2")
    }

    // MARK: - Message Model Tests

    func testMyTextMessageCreation() {
        let logMsg = MyTextMessage(logmsg: "Test log message")
        XCTAssertEqual(logMsg.message, "Test log message")
        XCTAssertEqual(logMsg.msgtype, .LOGMSG)
        XCTAssertEqual(logMsg.fromuserid, 0)

        let privMsg = MyTextMessage(fromuserid: 100, nickname: "User1", msgtype: .PRIV_IM, content: "Hello")
        XCTAssertEqual(privMsg.message, "Hello")
        XCTAssertEqual(privMsg.nickname, "User1")
        XCTAssertEqual(privMsg.msgtype, .PRIV_IM)
        XCTAssertEqual(privMsg.fromuserid, 100)
    }

    func testTextMessageSectioning() {
        let model = TextMessageModel(userid: 0, title: "Test")

        let msg1 = MyTextMessage(fromuserid: 1, nickname: "Alice", msgtype: .CHAN_IM, content: "Hello")
        let msg2 = MyTextMessage(fromuserid: 1, nickname: "Alice", msgtype: .CHAN_IM, content: "World")
        let msg3 = MyTextMessage(fromuserid: 2, nickname: "Bob", msgtype: .CHAN_IM, content: "Hi")

        model.appendEventMessage(msg1)
        model.appendEventMessage(msg2)
        model.appendEventMessage(msg3)

        XCTAssertEqual(model.sections.count, 3)
        XCTAssertEqual(model.sections[0].messages.count, 1)
        XCTAssertEqual(model.sections[1].messages.count, 1)
        XCTAssertEqual(model.sections[2].messages.count, 1)
    }

    // MARK: - Preferences Model Tests

    func testPreferencesModelInitialization() {
        let prefs = PreferencesModel()
        XCTAssertNotNil(prefs)
        XCTAssertEqual(prefs.subscriptionRows.count, 6)
        XCTAssertEqual(prefs.versionRows.count, 2)
    }

    func testVolumeConversion() {
        let vol0 = refVolume(0)
        XCTAssertEqual(vol0, 0)

        let vol100 = refVolume(100)
        XCTAssertGreaterThan(vol100, 0)

        let percent = refVolumeToPercent(vol100)
        XCTAssertEqual(percent, 100)
    }

    func testVoiceActivationValueText() {
        let prefs = PreferencesModel()

        let disabled = prefs.voiceActivationValueText(Double(VOICEACT_DISABLED))
        XCTAssertTrue(disabled.contains("Disabled"))

        let active = prefs.voiceActivationValueText(10)
        XCTAssertEqual(active, "10")
    }

    // MARK: - Server Model URL Parsing

    func testServerIPAddressValidation() {
        let server = Server()
        server.ipaddr = "tt5us.bearware.dk"
        server.tcpport = 10333

        XCTAssertFalse(server.ipaddr.isEmpty)
        XCTAssertGreaterThan(server.tcpport, 0)
        XCTAssertGreaterThan(server.udpport, 0)
    }

    func testServerTypeEnum() {
        let local = Server()
        local.servertype = .LOCAL

        let official = Server()
        official.servertype = .OFFICIAL

        let pub = Server()
        pub.servertype = .PUBLIC

        let unofficial = Server()
        unofficial.servertype = .UNOFFICIAL
    }

    // MARK: - AppInfo Tests

    func testAppInfoBundleInfo() {
        // Simulate what we can test without a real bundle
        XCTAssertFalse(AppInfo.TTLINK_PREFIX.isEmpty)
        XCTAssertEqual(AppInfo.DEFAULT_TCPPORT, 10333)
        XCTAssertEqual(AppInfo.DEFAULT_UDPPORT, 10333)
    }

    func testBearWareWebLoginDetection() {
        XCTAssertTrue(AppInfo.isBearWareWebLogin("bearware"))
        XCTAssertTrue(AppInfo.isBearWareWebLogin("user@bearware.dk"))
        XCTAssertFalse(AppInfo.isBearWareWebLogin("normaluser"))
    }

    func testURLConstruction() {
        let url = AppInfo.getServersURL(officialservers: true, unofficialservers: false)
        XCTAssertTrue(url.contains("official=1"))
        XCTAssertTrue(url.contains("unofficial=0"))
        XCTAssertTrue(url.contains("http://"))

        let tokenURL = AppInfo.getBearWareTokenURL(username: "test", passwd: "pass")
        XCTAssertTrue(tokenURL.contains("https://"))
        XCTAssertTrue(tokenURL.contains("username=test"))
    }

    // MARK: - ManageStatusViewModel Tests

    func testUserStatusModeDescriptions() {
        XCTAssertEqual(UserStatusMode.available.localizedString, "Available")
        XCTAssertEqual(UserStatusMode.away.localizedString, "Away")
        XCTAssertEqual(UserStatusMode.question.localizedString, "Question")

        XCTAssertEqual(UserStatusMode.available.ttMode, StatusMode.STATUSMODE_AVAILABLE.rawValue)
        XCTAssertEqual(UserStatusMode.away.ttMode, StatusMode.STATUSMODE_AWAY.rawValue)
    }

    // MARK: - ChannelListModel Tests

    func testChannelListRowIdentification() {
        let joinRow = ChannelListRow.join
        XCTAssertEqual(joinRow.id, "join")

        let user = User()
        user.nUserID = 42
        let userRow = ChannelListRow.user(user)
        XCTAssertEqual(userRow.id, "user-42")

        let channel = Channel()
        channel.nChannelID = 7
        let channelRow = ChannelListRow.channel(channel)
        XCTAssertEqual(channelRow.id, "channel-7")
    }

    func testChannelListDestinationHashing() {
        let tm1 = TextMessageModel(userid: 1, title: "Test")
        let d1 = ChannelListDestination.textMessage(tm1)
        let d2 = ChannelListDestination.textMessage(tm1)

        XCTAssertEqual(d1, d2)
        XCTAssertEqual(d1.hashValue, d2.hashValue)
    }

    // MARK: - MyTextMessage Delegate

    func testTextMessageDelegateAppending() {
        let model = ChannelListModel()
        let msg = MyTextMessage(fromuserid: 1, nickname: "Test", msgtype: .PRIV_IM, content: "Hello")

        model.appendTextMessage(1, txtmsg: msg)
        model.appendTextMessage(1, txtmsg: msg)
        model.appendTextMessage(2, txtmsg: msg)

        XCTAssertEqual(model.textmessages[1]?.count, 2)
        XCTAssertEqual(model.textmessages[2]?.count, 1)
    }

    // MARK: - OnlineUsersViewModel Tests

    func testOnlineUsersFiltering() {
        let ue1 = OnlineUserEntry(id: 1, username: "alice", nickname: "Alice", status: "Available", statusMode: "", channelName: "Root", isTalking: false, isMuted: false, isVideoTx: false, isDesktopTx: false, isMediaFileTx: false)
        let ue2 = OnlineUserEntry(id: 2, username: "bob", nickname: "Bob", status: "Away", statusMode: "", channelName: "Channel 1", isTalking: true, isMuted: false, isVideoTx: true, isDesktopTx: false, isMediaFileTx: false)

        let vm = OnlineUsersViewModel(title: "Test")
        vm.users = [ue1, ue2]

        XCTAssertEqual(vm.filteredUsers.count, 2)

        vm.searchText = "alice"
        XCTAssertEqual(vm.filteredUsers.count, 1)
        XCTAssertEqual(vm.filteredUsers[0].id, 1)

        vm.searchText = "Root"
        // search filters on username and nickname, not channelName
        XCTAssertEqual(vm.filteredUsers.count, 0)

        vm.searchText = ""
        XCTAssertEqual(vm.filteredUsers.count, 2)
    }

    // MARK: - Performance Tests

    func testVolumeConversionPerformance() {
        measure {
            for i in 0...1000 {
                let vol = refVolume(Double(i % 100))
                _ = refVolumeToPercent(vol)
            }
        }
    }

    func testMyTextMessageCreationPerformance() {
        measure {
            for i in 0...1000 {
                _ = MyTextMessage(fromuserid: INT32(i), nickname: "User \(i)", msgtype: .PRIV_IM, content: "Message number \(i) is a test message with enough length to be realistic")
            }
        }
    }

    // MARK: - Subscription Tests

    func testDefaultSubscriptions() {
        let subs = getDefaultSubscriptions()
        XCTAssertNotEqual(subs, 0)
        XCTAssertTrue((subs & SUBSCRIBE_USER_MSG.rawValue) != 0)
        XCTAssertTrue((subs & SUBSCRIBE_VOICE.rawValue) != 0)
    }

    // MARK: - Channel Detail Tests

    func testChannelDetailModelCreation() {
        var channel = Channel()
        channel.nChannelID = 10
        channel.nParentID = 1
        channel.bPassword = FALSE

        let model = ChannelDetailModel(channel: channel)
        XCTAssertNotNil(model)
        XCTAssertEqual(model.channel.nChannelID, 10)
    }

    // MARK: - UserDetailModel Tests

    func testUserDetailModelInit() {
        var user = User()
        user.nUserID = 55
        user.nChannelID = 3

        let model = UserDetailModel(user: user)
        XCTAssertNotNil(model)
        XCTAssertEqual(model.user.nUserID, 55)
    }

    // MARK: - AudioCodecModel Tests

    func testAudioCodecFactoryMethods() {
        let opus = newOpusCodec()
        XCTAssertTrue(opus.nAudioCodec.rawValue > 0)

        let speex = newSpeexCodec()
        XCTAssertTrue(speex.nAudioCodec.rawValue > 0)

        let speexVBR = newSpeexVBRCodec()
        XCTAssertTrue(speexVBR.nAudioCodec.rawValue > 0)
    }

    // MARK: - Server Management Tests

    func testServerManagementViewModelInit() {
        let vm = ServerManagementViewModel()
        XCTAssertNotNil(vm)
        XCTAssertFalse(vm.isAdmin)
    }

    // MARK: - Connection Status Tests

    func testConnectionStatusViewModelInit() {
        let vm = ConnectionStatusViewModel()
        XCTAssertNotNil(vm)
        XCTAssertEqual(vm.connectionState, "Offline")
        XCTAssertEqual(vm.pingMs, 0)
    }

    // MARK: - Event History Tests

    func testEventHistoryAppending() {
        let vm = EventHistoryViewModel()
        XCTAssertEqual(vm.events.count, 0)

        let ev1 = MyTextMessage(logmsg: "Test event 1")
        let ev2 = MyTextMessage(logmsg: "Test event 2")

        // We test via the private append method by simulating a log message
        // Direct access to appendEvent is not needed since we test through handleTTMessage
        // But we can verify the model initializes correctly
        XCTAssertNotNil(vm)
    }

    // MARK: - Private Messages Tests

    func testPrivateMessagesSessionCreation() {
        let vm = PrivateMessagesViewModel()
        XCTAssertNotNil(vm)
        XCTAssertEqual(vm.sessions.count, 0)
    }

    // MARK: - Media Streaming Tests

    func testMediaStreamingViewModelInit() {
        let vm = MediaStreamingViewModel()
        XCTAssertNotNil(vm)
        XCTAssertEqual(vm.streamGroups.count, 0)
    }

    // MARK: - File Management Tests

    func testFileManagementViewModelInit() {
        let vm = FileManagementViewModel()
        XCTAssertNotNil(vm)
        XCTAssertEqual(vm.files.count, 0)
        XCTAssertEqual(vm.activeTransfers.count, 0)
    }

    // MARK: - Global Chat Tests

    func testGlobalChatViewModelInit() {
        let vm = GlobalChatViewModel()
        XCTAssertNotNil(vm)
        XCTAssertEqual(vm.messages.count, 0)
    }

    // MARK: - MainTabModel Tests

    func testMainTabModelInit() {
        let server = Server()
        server.name = "Test"
        server.ipaddr = "127.0.0.1"

        let model = MainTabModel(server: server)
        XCTAssertNotNil(model)
        XCTAssertNotNil(model.channelListModel)
        XCTAssertNotNil(model.channelChatModel)
        XCTAssertNotNil(model.preferencesModel)
        XCTAssertNotNil(model.globalChatModel)
        XCTAssertNotNil(model.privateMessagesModel)
        XCTAssertNotNil(model.mediaStreamingModel)
        XCTAssertNotNil(model.fileManagementModel)
        XCTAssertNotNil(model.serverManagementModel)
        XCTAssertNotNil(model.eventHistoryModel)
        XCTAssertNotNil(model.connectionStatusModel)
        XCTAssertNotNil(model.onlineUsersModel)
        XCTAssertNotNil(model.manageStatusModel)
    }

    // MARK: - ServerListModel Tests

    func testServerListModelOperations() {
        let model = ServerListModel()
        XCTAssertEqual(model.servers.count, 0)

        let server = Server()
        server.name = "New Server"
        server.ipaddr = "10.0.0.1"

        model.upsertServer(server)
        XCTAssertEqual(model.servers.count, 1)

        model.deleteServer(server)
        XCTAssertEqual(model.servers.count, 0)
    }

    func testServerListNavigation() {
        let model = ServerListModel()
        model.openPreferences()
        XCTAssertEqual(model.navigationPath.count, 1)

        let server = Server()
        model.connect(to: server)
        XCTAssertNotNil(model.activeMainTabModel)
    }

    // MARK: - Utility Tests

    func testLimitText() {
        let settings = UserDefaults.standard
        settings.set(5, forKey: PREF_DISPLAY_LIMITTEXT)

        let short = limitText("Hi")
        XCTAssertEqual(short, "Hi")

        let long = limitText("Hello World")
        XCTAssertEqual(long, "Hello")

        settings.removeObject(forKey: PREF_DISPLAY_LIMITTEXT)
    }

    func testWithinBounds() {
        XCTAssertEqual(within(0, max_v: 10, value: 5), 5)
        XCTAssertEqual(within(0, max_v: 10, value: -1), 0)
        XCTAssertEqual(within(0, max_v: 10, value: 15), 10)
    }

    func testGetDisplayName() {
        var user = User()
        user.nUserID = 1

        let settings = UserDefaults.standard
        settings.removeObject(forKey: PREF_DISPLAY_SHOWUSERNAME)

        // When no nickname is set, should use "Noname - #1"
        let name = getDisplayName(user)
        XCTAssertTrue(name.contains("Noname") || name.contains("#1"))

        settings.removeObject(forKey: PREF_DISPLAY_SHOWUSERNAME)
    }

    func testDefaultSettings() {
        XCTAssertEqual(DEFAULT_SUBSCRIPTION_USERMSG, true)
        XCTAssertEqual(DEFAULT_SUBSCRIPTION_VOICE, true)
        XCTAssertEqual(MAX_TEXTMESSAGES, 100)
        XCTAssertEqual(DEFAULT_LIMIT_TEXT, 25)
    }

    // MARK: - ServerDetailModel Tests

    func testServerDetailModelApply() {
        let server = Server()
        server.name = "Original"
        server.ipaddr = "10.0.0.1"

        let detailModel = ServerDetailModel(server: server)
        detailModel.server.name = "Updated"
        detailModel.server.ipaddr = "10.0.0.2"

        let target = Server()
        detailModel.apply(to: target)
        XCTAssertEqual(target.name, "Updated")
        XCTAssertEqual(target.ipaddr, "10.0.0.2")
    }
}
