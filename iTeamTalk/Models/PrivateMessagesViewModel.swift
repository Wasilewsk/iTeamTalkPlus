import SwiftUI
import TeamTalkKit

struct PrivateChatSession: Identifiable {
    let id: INT32
    let user: User
    var lastMessage: MyTextMessage?
    var unreadCount: Int
}

final class PrivateMessagesViewModel: ObservableObject {
    @Published var sessions = [PrivateChatSession]()
    @Published var selectedSession: INT32?

    let title: String

    init(title: String = String(localized: "Private Messages", comment: "tab")) {
        self.title = title
        addToTTMessages(self)
    }

    deinit {
        removeAllTTMessageHandlers()
    }

    func session(for userID: INT32) -> PrivateChatSession? {
        sessions.first(where: { $0.id == userID })
    }

    func selectSession(_ userID: INT32) {
        selectedSession = userID
        unreadmessages.remove(userID)
        if let idx = sessions.firstIndex(where: { $0.id == userID }) {
            sessions[idx].unreadCount = 0
        }
    }

    func sendMessage(to userID: INT32, content: String) {
        guard !content.isEmpty else { return }

        var msg = TextMessage()
        msg.nFromUserID = TeamTalkClient.shared.myUserID
        msg.nMsgType = MSGTYPE_USER
        msg.nToUserID = userID

        let user = TeamTalkClient.shared.withUser(id: msg.nFromUserID) { $0 }
        let name = getDisplayName(user)
        let mymsg = MyTextMessage(fromuserid: msg.nFromUserID, nickname: name, msgtype: .PRIV_IM_MYSELF, content: content)

        if TeamTalkClient.shared.sendTextMessage(msg, content: content) {
            updateOrCreateSession(userID: userID, message: mymsg)
        }
    }

    private func updateOrCreateSession(userID: INT32, message: MyTextMessage) {
        if let idx = sessions.firstIndex(where: { $0.id == userID }) {
            sessions[idx].lastMessage = message
            sessions[idx].unreadCount = (sessions[idx].id == selectedSession) ? sessions[idx].unreadCount : sessions[idx].unreadCount + 1
        } else {
            let user = TeamTalkClient.shared.withUser(id: userID) { $0 }
            sessions.append(PrivateChatSession(id: userID, user: user, lastMessage: message, unreadCount: 0))
        }
    }
}

extension PrivateMessagesViewModel: TeamTalkEvent {
    func handleTTMessage(_ m: TTMessage) {
        switch m.nClientEvent {
        case CLIENTEVENT_CMD_USER_TEXTMSG:
            let txtmsg = TeamTalkMessagePayload.textMessage(from: m)
            guard txtmsg.nMsgType == MSGTYPE_USER else { return }

            let user = TeamTalkClient.shared.withUser(id: txtmsg.nFromUserID) { $0 }
            let name = getDisplayName(user)
            let msgtype: MsgType = TeamTalkClient.shared.myUserID == txtmsg.nFromUserID ? .PRIV_IM_MYSELF : .PRIV_IM
            let mymsg = MyTextMessage(fromuserid: txtmsg.nFromUserID, nickname: name, msgtype: msgtype, content: TeamTalkString.textMessage(txtmsg))

            updateOrCreateSession(userID: txtmsg.nFromUserID, message: mymsg)

        case CLIENTEVENT_CMD_USER_LOGGEDOUT:
            let user = TeamTalkMessagePayload.user(from: m)
            sessions.removeAll { $0.id == user.nUserID }

        default:
            break
        }
    }
}
