import SwiftUI
import TeamTalkKit

final class ConnectionStatusViewModel: ObservableObject, TeamTalkEvent {
    @Published var connectionState: String = String(localized: "Offline", comment: "conn status")
    @Published var serverName: String = ""
    @Published var myUserID: INT32 = 0
    @Published var myUsername: String = ""
    @Published var myChannel: String = ""

    let title: String

    init(title: String = String(localized: "Connection Status", comment: "tab")) {
        self.title = title
        addToTTMessages(self)
    }

    deinit {
        removeAllTTMessageHandlers()
    }

    func refreshStats() {
        let connected = TeamTalkClient.shared.isConnected
        connectionState = connected
            ? String(localized: "Online", comment: "conn status")
            : String(localized: "Offline", comment: "conn status")

        if connected {
            serverName = TeamTalkClient.shared.withServerProperties {
                TeamTalkString.serverProperties(.name, from: $0)
            }

            myUserID = TeamTalkClient.shared.myUserID
            if myUserID > 0 {
                let user = TeamTalkClient.shared.withUser(id: myUserID) { $0 }
                myUsername = getDisplayName(user)
            }

            let channelID = TeamTalkClient.shared.myChannelID
            if channelID > 0 {
                myChannel = TeamTalkClient.shared.withChannel(id: channelID) {
                    TeamTalkString.channel(.name, from: $0)
                }
            } else {
                myChannel = ""
            }
        } else {
            serverName = ""
            myUserID = 0
            myUsername = ""
            myChannel = ""
        }
    }

    func handleTTMessage(_ m: TTMessage) {
        switch m.nClientEvent {
        case CLIENTEVENT_CON_SUCCESS,
            CLIENTEVENT_CON_LOST,
            CLIENTEVENT_CON_FAILED,
            CLIENTEVENT_CMD_MYSELF_LOGGEDIN,
            CLIENTEVENT_CMD_MYSELF_LOGGEDOUT,
            CLIENTEVENT_CMD_USER_JOINED:
            refreshStats()
        default:
            break
        }
    }
}
