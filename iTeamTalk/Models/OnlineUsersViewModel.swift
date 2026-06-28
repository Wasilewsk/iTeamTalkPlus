import SwiftUI
import TeamTalkKit

struct OnlineUserEntry: Identifiable {
    let id: INT32
    let username: String
    let nickname: String
    let status: String
    let statusMode: String
    let channelName: String
    let isTalking: Bool
    let isMuted: Bool
    let isVideoTx: Bool
    let isDesktopTx: Bool
    let isMediaFileTx: Bool
}

final class OnlineUsersViewModel: ObservableObject {
    @Published var users = [OnlineUserEntry]()
    @Published var searchText = ""
    @Published var selectedUserID: INT32?

    let title: String

    var filteredUsers: [OnlineUserEntry] {
        if searchText.isEmpty { return users }
        return users.filter {
            $0.username.localizedCaseInsensitiveContains(searchText) ||
            $0.nickname.localizedCaseInsensitiveContains(searchText)
        }
    }

    init(title: String = String(localized: "Online Users", comment: "tab")) {
        self.title = title
        addToTTMessages(self)
    }

    deinit {
        removeAllTTMessageHandlers()
    }

    func refreshUsers() {
        let allUsers = TeamTalkClient.shared.getAllUsers()
        users = allUsers.map { user in
            let isFemale = (UInt(user.nStatusMode) & StatusMode.STATUSMODE_FEMALE.rawValue) != 0
            let statusModeStr: String
            if (UInt(user.nStatusMode) & StatusMode.STATUSMODE_AWAY.rawValue) != 0 {
                statusModeStr = String(localized: "Away", comment: "online users")
            } else if (UInt(user.nStatusMode) & StatusMode.STATUSMODE_QUESTION.rawValue) != 0 {
                statusModeStr = String(localized: "Question", comment: "online users")
            } else {
                statusModeStr = isFemale ? String(localized: "Female", comment: "online users") : String(localized: "Available", comment: "online users")
            }

            let channelName = TeamTalkClient.shared.withChannel(id: user.nChannelID) { TeamTalkString.channel(.name, from: $0) } ?? ""
            let isTalking = (user.uUserState & USERSTATE_VOICE.rawValue) != 0
            let isMuted = (user.uUserState & USERSTATE_MUTE_VOICE.rawValue) != 0

            return OnlineUserEntry(
                id: user.nUserID,
                username: TeamTalkString.user(.username, from: user),
                nickname: getDisplayName(user),
                status: TeamTalkString.user(.statusMessage, from: user),
                statusMode: statusModeStr,
                channelName: channelName,
                isTalking: isTalking,
                isMuted: isMuted,
                isVideoTx: (user.uUserState & USERSTATE_VIDEOCAPTURE.rawValue) != 0,
                isDesktopTx: (user.uUserState & USERSTATE_DESKTOP.rawValue) != 0,
                isMediaFileTx: (user.uUserState & USERSTATE_MEDIAFILE.rawValue) != 0
            )
        }
    }

    func showUserDetail(userID: INT32) {
        selectedUserID = userID
    }
}

extension OnlineUsersViewModel: TeamTalkEvent {
    func handleTTMessage(_ m: TTMessage) {
        switch m.nClientEvent {
        case CLIENTEVENT_CMD_USER_LOGGEDIN,
            CLIENTEVENT_CMD_USER_LOGGEDOUT,
            CLIENTEVENT_CMD_USER_JOINED,
            CLIENTEVENT_CMD_USER_LEFT,
            CLIENTEVENT_CMD_USER_UPDATE,
            CLIENTEVENT_USER_STATECHANGE:
            refreshUsers()
        default:
            break
        }
    }
}
