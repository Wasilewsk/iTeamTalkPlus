import SwiftUI
import TeamTalkKit

final class EventHistoryViewModel: ObservableObject {
    @Published var events = [MyTextMessage]()

    let title: String

    init(title: String = String(localized: "Event History", comment: "tab")) {
        self.title = title
        addToTTMessages(self)
    }

    deinit {
        removeAllTTMessageHandlers()
    }

    private func appendEvent(_ msg: MyTextMessage) {
        events.append(msg)
        while events.count > MAX_TEXTMESSAGES {
            events.removeFirst()
        }
    }
}

extension EventHistoryViewModel: TeamTalkEvent {
    func handleTTMessage(_ m: TTMessage) {
        switch m.nClientEvent {
        case CLIENTEVENT_CMD_USER_LOGGEDIN:
            let user = TeamTalkMessagePayload.user(from: m)
            let name = getDisplayName(user)
            appendEvent(MyTextMessage(logmsg: String(format: String(localized: "%@ logged on", comment: "event"), name)))

        case CLIENTEVENT_CMD_USER_LOGGEDOUT:
            let user = TeamTalkMessagePayload.user(from: m)
            let name = getDisplayName(user)
            appendEvent(MyTextMessage(logmsg: String(format: String(localized: "%@ logged off", comment: "event"), name)))

        case CLIENTEVENT_CMD_USER_JOINED:
            let user = TeamTalkMessagePayload.user(from: m)
            let name = getDisplayName(user)
            if let channel = TeamTalkClient.shared.withChannel(id: user.nChannelID, { TeamTalkString.channel(.name, from: $0) }) {
                appendEvent(MyTextMessage(logmsg: String(format: String(localized: "%@ joined %@", comment: "event"), name, channel)))
            }

        case CLIENTEVENT_CMD_USER_LEFT:
            let user = TeamTalkMessagePayload.user(from: m)
            let name = getDisplayName(user)
            appendEvent(MyTextMessage(logmsg: String(format: String(localized: "%@ left channel", comment: "event"), name)))

        case CLIENTEVENT_CON_SUCCESS:
            appendEvent(MyTextMessage(logmsg: String(localized: "Connected to server", comment: "event")))

        case CLIENTEVENT_CON_LOST:
            appendEvent(MyTextMessage(logmsg: String(localized: "Connection lost", comment: "event")))

        case CLIENTEVENT_CON_FAILED:
            appendEvent(MyTextMessage(logmsg: String(localized: "Connection failed", comment: "event")))

        case CLIENTEVENT_CMD_MYSELF_LOGGEDIN:
            appendEvent(MyTextMessage(logmsg: String(localized: "Logged in to server", comment: "event")))

        case CLIENTEVENT_CMD_MYSELF_KICKED:
            appendEvent(MyTextMessage(logmsg: String(localized: "You were kicked from server", comment: "event")))

        case CLIENTEVENT_CMD_MYSELF_LOGGEDOUT:
            appendEvent(MyTextMessage(logmsg: String(localized: "Logged out of server", comment: "event")))

        case CLIENTEVENT_CMD_CHANNEL_NEW:
            let channel = TeamTalkMessagePayload.channel(from: m)
            appendEvent(MyTextMessage(logmsg: String(format: String(localized: "Channel '%@' created", comment: "event"), TeamTalkString.channel(.name, from: channel))))

        case CLIENTEVENT_CMD_CHANNEL_REMOVE:
            let channel = TeamTalkMessagePayload.channel(from: m)
            appendEvent(MyTextMessage(logmsg: String(format: String(localized: "Channel '%@' removed", comment: "event"), TeamTalkString.channel(.name, from: channel))))

        default:
            break
        }
    }
}
