import SwiftUI
import TeamTalkKit

fileprivate func ttStr<T>(_ value: T) -> String {
    withUnsafePointer(to: value) {
        String(cString: UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self))
    }
}

struct UserAccountEntry: Identifiable {
    let id: Int32
    let username: String
    let userType: String
    let userRights: UInt32
}

struct BanEntry: Identifiable {
    let id: String
    let ipAddress: String
    let username: String
}

struct ServerStatisticsEntry {
    var totalUsers: Int
    var totalChannels: Int
    var uptime: String
}

final class ServerManagementViewModel: ObservableObject, TeamTalkEvent {
    @Published var userAccounts = [UserAccountEntry]()
    @Published var banEntries = [BanEntry]()
    @Published var serverStats = ServerStatisticsEntry(totalUsers: 0, totalChannels: 0, uptime: "0s")
    @Published var isLoading = false
    @Published var errorMessage: String?

    let title: String

    var isAdmin: Bool {
        TeamTalkClient.shared.withUser(id: TeamTalkClient.shared.myUserID) { user in
            (user.uUserType & USERTYPE_ADMIN.rawValue) != 0
        }
    }

    private var listAccountsCmdID: INT32 = 0
    private var listBansCmdID: INT32 = 0
    private var accumulatedAccounts = [UserAccountEntry]()
    private var accumulatedBans = [BanEntry]()
    private var queryStatsCmdID: INT32 = 0
    private var collectingBans = false
    private var collectingAccounts = false

    init(title: String = String(localized: "Server Management", comment: "tab")) {
        self.title = title
        addToTTMessages(self)
    }

    deinit {
        removeAllTTMessageHandlers()
    }

    func refreshAll() {
        refreshUserAccounts()
        refreshBanList()
        refreshServerProperties()
    }

    func refreshUserAccounts() {
        guard isAdmin else { return }
        isLoading = true
        accumulatedAccounts.removeAll()
        collectingAccounts = true
        listAccountsCmdID = TeamTalkClient.shared.doListUserAccounts(index: 0, count: 0)
    }

    func refreshBanList() {
        guard isAdmin else { return }
        accumulatedBans.removeAll()
        collectingBans = true
        listBansCmdID = TeamTalkClient.shared.doListBans(channelID: 0, index: 0, count: 0)
    }

    func refreshServerProperties() {
        let users = TeamTalkClient.shared.getServerUsers().count
        let channels = TeamTalkClient.shared.getServerChannels().count
        queryStatsCmdID = TeamTalkClient.shared.doQueryServerStats()

        serverStats = ServerStatisticsEntry(
            totalUsers: users,
            totalChannels: channels,
            uptime: serverStats.uptime
        )
    }

    func kickUser(userID: INT32) {
        TeamTalkClient.shared.kickUser(id: userID, fromChannelID: 0)
    }

    func banUser(userID: INT32) {
        TeamTalkClient.shared.banUser(id: userID, fromChannelID: 0)
        TeamTalkClient.shared.kickUser(id: userID, fromChannelID: 0)
    }

    func removeBan(ipAddress: String) {
        TeamTalkClient.shared.doUnBanUser(ipAddress: ipAddress, channelID: 0)
        refreshBanList()
    }

    func handleTTMessage(_ m: TTMessage) {
        switch m.nClientEvent {
        case CLIENTEVENT_CMD_SERVER_UPDATE:
            refreshServerProperties()

        case CLIENTEVENT_CMD_USERACCOUNT where collectingAccounts:
            let account = TeamTalkMessagePayload.userAccount(from: m)
            let typeStr: String
            if (account.uUserType & USERTYPE_ADMIN.rawValue) != 0 {
                typeStr = String(localized: "Admin", comment: "server mgmt")
            } else if (account.uUserType & USERTYPE_DEFAULT.rawValue) != 0 {
                typeStr = String(localized: "Default", comment: "server mgmt")
            } else {
                typeStr = String(localized: "User", comment: "server mgmt")
            }
            let entry = UserAccountEntry(
                id: listAccountsCmdID,
                username: ttStr(account.szUsername),
                userType: typeStr,
                userRights: account.uUserRights
            )
            accumulatedAccounts.append(entry)

        case CLIENTEVENT_CMD_SERVERSTATISTICS where m.nSource == queryStatsCmdID:
            let stats = TeamTalkMessagePayload.serverStatistics(from: m)
            let totalMSec = stats.nUptimeMSec
            let totalSeconds = Int(totalMSec / 1000)
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60
            serverStats = ServerStatisticsEntry(
                totalUsers: serverStats.totalUsers,
                totalChannels: serverStats.totalChannels,
                uptime: String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            )

        case CLIENTEVENT_CMD_PROCESSING where !TeamTalkMessagePayload.isActive(m):
            if m.nSource == listAccountsCmdID {
                userAccounts = accumulatedAccounts
                isLoading = false
                collectingAccounts = false
            } else if m.nSource == listBansCmdID {
                banEntries = accumulatedBans
                collectingBans = false
            }

        case CLIENTEVENT_CMD_BANNEDUSER where collectingBans:
            let banned = TeamTalkMessagePayload.bannedUser(from: m)
            let entry = BanEntry(
                id: ttStr(banned.szIPAddress),
                ipAddress: ttStr(banned.szIPAddress),
                username: ttStr(banned.szUsername)
            )
            accumulatedBans.append(entry)

        default:
            break
        }
    }
}
