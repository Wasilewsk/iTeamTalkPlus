import SwiftUI
import TeamTalkKit

final class GlobalChatViewModel: ObservableObject {
    @Published var messages = [MyTextMessage]()
    @Published var composedText = ""

    var userid: INT32 { 0 }
    let title: String

    init(title: String = String(localized: "Global Chat", comment: "tab")) {
        self.title = title
        addToTTMessages(self)
    }

    deinit {
        removeAllTTMessageHandlers()
    }

    func sendMessage() {
        let content = composedText
        guard !content.isEmpty else { return }

        var msg = TextMessage()
        msg.nFromUserID = TeamTalkClient.shared.myUserID
        msg.nMsgType = MSGTYPE_BROADCAST

        let mymsg = MyTextMessage(
            fromuserid: msg.nFromUserID,
            nickname: getDisplayName(TeamTalkClient.shared.withUser(id: msg.nFromUserID) { $0 }),
            msgtype: .BCAST,
            content: content
        )

        if TeamTalkClient.shared.sendTextMessage(msg, content: content) {
            messages.append(mymsg)
            composedText = ""
            trimMessages()
        }
    }

    private func trimMessages() {
        while messages.count > MAX_TEXTMESSAGES {
            messages.removeFirst()
        }
    }

    // MARK: - TTS

    func speakLastMessage() {
        guard let msg = messages.last else { return }
        speakTextMessage(MSGTYPE_BROADCAST, mymsg: msg)
    }
}

extension GlobalChatViewModel: TeamTalkEvent {
    func handleTTMessage(_ m: TTMessage) {
        switch m.nClientEvent {
        case CLIENTEVENT_CMD_USER_TEXTMSG:
            let txtmsg = TeamTalkMessagePayload.textMessage(from: m)
            guard txtmsg.nMsgType == MSGTYPE_BROADCAST else { return }

            let user = TeamTalkClient.shared.withUser(id: txtmsg.nFromUserID) { $0 }
            let name = getDisplayName(user)
            let msgtype: MsgType = TeamTalkClient.shared.myUserID == txtmsg.nFromUserID ? .BCAST : .BCAST
            let mymsg = MyTextMessage(fromuserid: txtmsg.nFromUserID, nickname: name, msgtype: msgtype, content: TeamTalkString.textMessage(txtmsg))
            messages.append(mymsg)
            trimMessages()

        default:
            break
        }
    }
}
