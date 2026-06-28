import Foundation
import TeamTalkKit

actor TeamTalkService {
    static let shared = TeamTalkService()

    private let client = TeamTalkClient.shared

    // MARK: - Connection

    func connect(host: String, tcpPort: Int, udpPort: Int, encrypted: Bool) -> Bool {
        client.connect(toHost: host, tcpPort: INT32(tcpPort), udpPort: INT32(udpPort), encrypted: encrypted)
    }

    func disconnect() {
        client.disconnect()
    }

    func login(nickname: String, username: String, password: String) -> INT32 {
        client.login(nickname: nickname, username: username, password: password, clientName: AppInfo.getAppName())
    }

    var isConnected: Bool { client.isConnected }
    var isAuthorized: Bool { client.isAuthorized }
    var myUserID: INT32 { client.myUserID }
    var myChannelID: INT32 { client.myChannelID }
    var myUserRights: UINT32 { client.myUserRights }
    var rootChannelID: INT32 { client.rootChannelID }
    var serverIPAddress: String { client.serverIPAddress }
    var pingTime: UInt32 { client.pingTime }
    var statisticsReceivedBytes: Int64 { client.statisticsReceivedBytes }
    var statisticsSentBytes: Int64 { client.statisticsSentBytes }
    var statisticsReceiveKbps: Double { client.statisticsReceiveKbps }
    var statisticsSendKbps: Double { client.statisticsSendKbps }
    var serverProperties: ServerProperties { client.serverProperties }

    // MARK: - Channels

    func getChannel(id: INT32) -> Channel {
        client.withChannel(id: id) { $0 } ?? Channel()
    }

    func getAllChannels() -> [Channel] {
        client.getAllChannels()
    }

    func channelID(fromPath path: String) -> INT32 {
        client.channelID(fromPath: path)
    }

    func joinChannel(id: INT32, password: String = "") -> INT32 {
        client.joinChannel(id: id, password: password)
    }

    func join(channel: inout Channel) -> INT32 {
        client.join(channel: &channel)
    }

    func leaveChannel() -> INT32 {
        client.leaveChannel()
    }

    // MARK: - Users

    func getAllUsers() -> [User] {
        client.getAllUsers()
    }

    func getUser(id: INT32) -> User {
        client.withUser(id: id) { $0 } ?? User()
    }

    func getDisplayName(for userID: INT32) -> String {
        let user = getUser(id: userID)
        return getDisplayName(user)
    }

    func changeNickname(_ nickname: String) {
        client.changeNickname(nickname)
    }

    func changeStatus(mode: INT32) {
        client.changeStatus(mode: mode)
    }

    func changeStatusMessage(_ message: String) {
        client.changeStatusMessage(message)
    }

    func setUserMute(userID: INT32, stream: StreamType, muted: Bool) {
        client.setUserMute(userID: userID, stream: stream, muted: muted)
    }

    func setUserVolume(userID: INT32, stream: StreamType, volume: INT32) {
        client.setUserVolume(userID: userID, stream: stream, volume: volume)
    }

    func kickUser(userID: INT32, fromChannelID: INT32) -> INT32 {
        client.kickUser(id: userID, fromChannelID: fromChannelID)
    }

    func banUser(userID: INT32, fromChannelID: INT32) -> INT32 {
        client.banUser(id: userID, fromChannelID: fromChannelID)
    }

    func moveUser(userID: INT32, toChannelID: INT32) -> INT32 {
        client.moveUser(id: userID, toChannelID: toChannelID)
    }

    // MARK: - Messaging

    func sendTextMessage(_ msg: TextMessage, content: String) -> Bool {
        client.sendTextMessage(msg, content: content)
    }

    // MARK: - Audio

    func enableVoiceTransmission(_ enable: Bool) {
        client.enableVoiceTransmission(enable)
    }

    var isVoiceTransmitting: Bool { client.isVoiceTransmitting }

    func initSoundInputDevice(id: TeamTalkSoundDeviceID) -> Bool {
        client.initSoundInputDevice(id: id)
    }

    func initSoundOutputDevice(id: TeamTalkSoundDeviceID) -> Bool {
        client.initSoundOutputDevice(id: id)
    }

    func closeSoundDevices() {
        client.closeSoundDevices()
    }

    func setSoundOutputVolume(_ volume: INT32) {
        client.setSoundOutputVolume(volume)
    }

    func setSoundInputGainLevel(_ level: INT32) {
        client.setSoundInputGainLevel(level)
    }

    var soundOutputVolume: UInt32 { client.soundOutputVolume }
    var soundInputGainLevel: UInt32 { client.soundInputGainLevel }

    func enableVoiceActivation(_ enable: Bool) {
        client.enableVoiceActivation(enable)
    }

    func setVoiceActivationLevel(_ level: INT32) {
        client.setVoiceActivationLevel(level)
    }

    func setSoundInputPreprocess(_ preprocessor: inout TeamTalkAudioPreprocessor) {
        client.setSoundInputPreprocess(&preprocessor)
    }

    // MARK: - Files

    func getFiles(channelID: INT32) -> [RemoteFile] {
        client.getFiles(channelID: channelID)
    }

    func uploadFile(channelID: INT32, localFilePath: String) -> INT32 {
        client.uploadFile(channelID: channelID, localFilePath: localFilePath)
    }

    func downloadFile(channelID: INT32, remoteFileID: INT32, localFilePath: String) -> INT32 {
        client.downloadFile(channelID: channelID, remoteFileID: remoteFileID, localFilePath: localFilePath)
    }

    func deleteFile(channelID: INT32, remoteFileID: INT32) {
        client.deleteFile(channelID: channelID, remoteFileID: remoteFileID)
    }

    // MARK: - Admin

    func getAllUserAccounts() -> [UserAccount] {
        client.getAllUserAccounts()
    }

    func getAllBans() -> [Ban] {
        client.getAllBans()
    }

    func removeBan(banID: INT32) {
        client.removeBan(banID: banID)
    }

    func setServerProperties(_ props: ServerProperties) {
        client.setServerProperties(props)
    }

    // MARK: - Subscriptions

    func subscribe(userID: INT32, subscriptions: UINT32) {
        client.subscribe(userID: userID, subscriptions: subscriptions)
    }

    func unsubscribe(userID: INT32, subscriptions: UINT32) {
        client.unsubscribe(userID: userID, subscriptions: subscriptions)
    }

    func isChannelOperator(channelID: INT32) -> Bool {
        client.isChannelOperator(channelID: channelID)
    }

    // MARK: - Encryption

    func configureEncryption(_ config: TeamTalkEncryptionConfiguration) throws -> Bool {
        try client.configureEncryption(config)
    }

    // MARK: - Streaming

    func stopStreaming(userID: INT32) {
        client.stopStreaming(userID: userID)
    }
}
