import SwiftUI
import TeamTalkKit

final class ConnectionStatusViewModel: ObservableObject {
    @Published var connectionState: String = String(localized: "Offline", comment: "conn status")
    @Published var serverName: String = ""
    @Published var serverIP: String = ""
    @Published var pingMs: Int = 0
    @Published var rxBytes: Int64 = 0
    @Published var txBytes: Int64 = 0
    @Published var rxKbps: Double = 0
    @Published var txKbps: Double = 0
    @Published var uptime: String = "00:00:00"
    @Published var myUserID: INT32 = 0
    @Published var myUsername: String = ""
    @Published var myChannel: String = ""

    let title: String

    private var timer: Timer?

    init(title: String = String(localized: "Connection Status", comment: "tab")) {
        self.title = title
        addToTTMessages(self)
        startPolling()
    }

    deinit {
        timer?.invalidate()
        removeAllTTMessageHandlers()
    }

    func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.refreshStats()
        }
    }

    func refreshStats() {
        let connected = TeamTalkClient.shared.isConnected
        connectionState = connected
            ? String(localized: "Online", comment: "conn status")
            : String(localized: "Offline", comment: "conn status")

        if connected {
            serverName = TeamTalkClient.shared.withServerProperties { TeamTalkString.serverProperties(.name, from: $0) } ?? ""
            serverIP = TeamTalkClient.shared.serverIPAddress
            myUserID = TeamTalkClient.shared.myUserID

            let user = TeamTalkClient.shared.withUser(id: myUserID) { $0 }
            myUsername = getDisplayName(user)

            if TeamTalkClient.shared.myChannelID > 0 {
                myChannel = TeamTalkClient.shared.withChannel(id: TeamTalkClient.shared.myChannelID) { TeamTalkString.channel(.name, from: $0) } ?? ""
            }

            pingMs = Int(TeamTalkClient.shared.pingTime)
            rxBytes = TeamTalkClient.shared.statisticsReceivedBytes
            txBytes = TeamTalkClient.shared.statisticsSentBytes
            rxKbps = TeamTalkClient.shared.statisticsReceiveKbps
            txKbps = TeamTalkClient.shared.statisticsSendKbps
        } else {
            serverName = ""
            serverIP = ""
            myUserID = 0
            myUsername = ""
            myChannel = ""
            pingMs = 0
            rxBytes = 0
            txBytes = 0
            rxKbps = 0
            txKbps = 0
        }
    }
}

extension ConnectionStatusViewModel: TeamTalkEvent {
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
