import Foundation
import TeamTalkKit

final class TeamTalkService {
    static let shared = TeamTalkService()

    private let client = TeamTalkClient.shared

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
    var myUserRights: UInt32 { client.myUserRights }
    var rootChannelID: INT32 { client.rootChannelID }

    func withUser<T>(id userID: INT32, _ body: (inout User) -> T) -> T {
        client.withUser(id: userID, body)
    }

    func withChannel<T>(id channelID: INT32, _ body: (inout Channel) -> T) -> T {
        client.withChannel(id: channelID, body)
    }

    func withServerProperties<T>(_ body: (inout ServerProperties) -> T) -> T {
        client.withServerProperties(body)
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

    func changeNickname(_ nickname: String) {
        client.changeNickname(nickname)
    }

    func changeStatus(mode: INT32, message: String = "") {
        client.changeStatus(mode: mode, message: message)
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

    func sendTextMessage(_ msg: TextMessage, content: String) -> Bool {
        client.sendTextMessage(msg, content: content)
    }

    func enableVoiceTransmission(_ enable: Bool) {
        client.enableVoiceTransmission(enable)
    }

    var isVoiceTransmitting: Bool { client.isVoiceTransmitting }

    func initSoundInputDevice(id: INT32) -> Bool {
        client.initSoundInputDevice(id: id)
    }

    func initSoundOutputDevice(id: INT32) -> Bool {
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

    var soundOutputVolume: INT32 { client.soundOutputVolume }
    var soundInputGainLevel: INT32 { client.soundInputGainLevel }

    func enableVoiceActivation(_ enable: Bool) {
        client.enableVoiceActivation(enable)
    }

    func setVoiceActivationLevel(_ level: INT32) {
        client.setVoiceActivationLevel(level)
    }

    func subscribe(userID: INT32, subscriptions: UInt32) {
        client.subscribe(userID: userID, subscriptions: subscriptions)
    }

    func unsubscribe(userID: INT32, subscriptions: UInt32) {
        client.unsubscribe(userID: userID, subscriptions: subscriptions)
    }

    func isChannelOperator(channelID: INT32) -> Bool {
        client.isChannelOperator(channelID: channelID)
    }

    func configureEncryption(_ config: TeamTalkEncryptionConfiguration) throws -> Bool {
        try client.configureEncryption(config)
    }

    // C API helpers

    func doSendFile(channelID: INT32, localFilePath: String) -> INT32 {
        client.doSendFile(channelID: channelID, localFilePath: localFilePath)
    }

    func doRecvFile(channelID: INT32, fileID: INT32, localFilePath: String) -> INT32 {
        client.doRecvFile(channelID: channelID, fileID: fileID, localFilePath: localFilePath)
    }

    func doDeleteFile(channelID: INT32, fileID: INT32) -> INT32 {
        client.doDeleteFile(channelID: channelID, fileID: fileID)
    }

    func getChannelFiles(channelID: INT32) -> [RemoteFile] {
        client.getChannelFiles(channelID: channelID)
    }

    func doListUserAccounts(index: INT32, count: INT32) -> INT32 {
        client.doListUserAccounts(index: index, count: count)
    }

    func doNewUserAccount(_ account: UserAccount) -> INT32 {
        client.doNewUserAccount(account)
    }

    func doDeleteUserAccount(username: String) -> INT32 {
        client.doDeleteUserAccount(username: username)
    }

    func doListBans(channelID: INT32, index: INT32, count: INT32) -> INT32 {
        client.doListBans(channelID: channelID, index: index, count: count)
    }

    func doUnBanUser(ipAddress: String, channelID: INT32) -> INT32 {
        client.doUnBanUser(ipAddress: ipAddress, channelID: channelID)
    }

    func doQueryServerStats() -> INT32 {
        client.doQueryServerStats()
    }

    func getServerChannels() -> [Channel] {
        client.getServerChannels()
    }

    func getServerUsers() -> [User] {
        client.getServerUsers()
    }
}
