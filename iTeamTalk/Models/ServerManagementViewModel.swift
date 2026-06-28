import SwiftUI
import TeamTalkKit

struct UserAccountEntry: Identifiable {
    let id: Int32
    let username: String
    let userType: String
    let userRights: UINT32
}

struct BanEntry: Identifiable {
    let id: Int
    let ipAddress: String
    let username: String
}

struct ServerStatistics {
    var totalUsers: Int
    var totalChannels: Int
    var uptime: String
    var totalFiles: Int
}

final class ServerManagementViewModel: ObservableObject {
    @Published var userAccounts = [UserAccountEntry]()
    @Published var banEntries = [BanEntry]()
    @Published var serverStats = ServerStatistics(totalUsers: 0, totalChannels: 0, uptime: "0s", totalFiles: 0)
    @Published var isLoading = false
    @Published var errorMessage: String?

    let title: String
    var isAdmin: Bool {
        (TeamTalkClient.shared.myUserRights & USERRIGHT_ADMIN.rawValue) != 0 ||
        (TeamTalkClient.shared.myUserRights & 0xFFFFFFFF) != 0
    }

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
        isLoading = true
        let accounts = TeamTalkClient.shared.getAllUserAccounts()
        userAccounts = accounts.map { account in
            let typeStr: String
            if (account.uUserType & USERTYPE_ADMIN.rawValue) != 0 {
                typeStr = String(localized: "Admin", comment: "server mgmt")
            } else if (account.uUserType & USERTYPE_DEFAULT.rawValue) != 0 {
                typeStr = String(localized: "Default", comment: "server mgmt")
            } else {
                typeStr = String(localized: "User", comment: "server mgmt")
            }
            return UserAccountEntry(
                id: account.nUserID,
                username: TeamTalkString.userAccount(.username, from: account),
                userType: typeStr,
                userRights: account.uUserRights
            )
        }
        isLoading = false
    }

    func refreshBanList() {
        let bans = TeamTalkClient.shared.getAllBans()
        banEntries = bans.map { ban in
            BanEntry(id: Int(ban.nBanID), ipAddress: TeamTalkString.ban(.ipAddress, from: ban), username: TeamTalkString.ban(.username, from: ban))
        }
    }

    func refreshServerProperties() {
        let props = TeamTalkClient.shared.serverProperties
        let users = TeamTalkClient.shared.getAllUsers().count
        let channels = TeamTalkClient.shared.getAllChannels().count
        let files = TeamTalkClient.shared.getAllFiles().count

        let uptimeSeconds = props.nTimeStarted > 0 ? Int(Date().timeIntervalSince1970) - Int(props.nTimeStarted) : 0
        let hours = uptimeSeconds / 3600
        let minutes = (uptimeSeconds % 3600) / 60
        let seconds = uptimeSeconds % 60

        serverStats = ServerStatistics(
            totalUsers: users,
            totalChannels: channels,
            uptime: String(format: "%02d:%02d:%02d", hours, minutes, seconds),
            totalFiles: files
        )
    }

    func kickUser(userID: INT32) {
        let cmdid = TeamTalkClient.shared.kickUser(id: userID, fromChannelID: 0)
        _ = cmdid
    }

    func banUser(userID: INT32) {
        let cmdid = TeamTalkClient.shared.banUser(id: userID, fromChannelID: 0)
        _ = cmdid
        TeamTalkClient.shared.kickUser(id: userID, fromChannelID: 0)
    }

    func removeBan(banID: Int) {
        TeamTalkClient.shared.removeBan(banID: INT32(banID))
        refreshBanList()
    }

    func saveServerProperties(_ props: ServerProperties) {
        TeamTalkClient.shared.setServerProperties(props)
    }
}

extension ServerManagementViewModel: TeamTalkEvent {
    func handleTTMessage(_ m: TTMessage) {
        switch m.nClientEvent {
        case CLIENTEVENT_CMD_SERVER_UPDATE,
            CLIENTEVENT_CMD_USER_LOGGEDIN,
            CLIENTEVENT_CMD_USER_LOGGEDOUT:
            refreshServerProperties()
        default:
            break
        }
    }
}
