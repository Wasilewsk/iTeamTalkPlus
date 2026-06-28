import SwiftUI
import TeamTalkKit

enum UserStatusMode: Int, CaseIterable {
    case available = 0
    case away
    case question

    var localizedString: String {
        switch self {
        case .available: return String(localized: "Available", comment: "status")
        case .away: return String(localized: "Away", comment: "status")
        case .question: return String(localized: "Question", comment: "status")
        }
    }

    var ttMode: UInt {
        switch self {
        case .available: return StatusMode.STATUSMODE_AVAILABLE.rawValue
        case .away: return StatusMode.STATUSMODE_AWAY.rawValue
        case .question: return StatusMode.STATUSMODE_QUESTION.rawValue
        }
    }
}

final class ManageStatusViewModel: ObservableObject, TeamTalkEvent {
    @Published var selectedMode: UserStatusMode = .available
    @Published var statusMessage: String = ""
    @Published var isFemale: Bool = false
    @Published var isVideoTx: Bool = false
    @Published var isDesktopTx: Bool = false
    @Published var isStreamingMedia: Bool = false

    let title: String

    init(title: String = String(localized: "Manage Status", comment: "tab")) {
        self.title = title
        addToTTMessages(self)

        if let savedMessage = UserDefaults.standard.string(forKey: "user_status_message") {
            statusMessage = savedMessage
        }

        refreshCurrentStatus()
    }

    deinit {
        removeAllTTMessageHandlers()
    }

    func refreshCurrentStatus() {
        let myID = TeamTalkClient.shared.myUserID
        guard myID > 0 else { return }

        let user = TeamTalkClient.shared.withUser(id: myID) { $0 }

        if (UInt(user.nStatusMode) & StatusMode.STATUSMODE_AWAY.rawValue) != 0 {
            selectedMode = .away
        } else if (UInt(user.nStatusMode) & StatusMode.STATUSMODE_QUESTION.rawValue) != 0 {
            selectedMode = .question
        } else {
            selectedMode = .available
        }

        isFemale = (UInt(user.nStatusMode) & StatusMode.STATUSMODE_FEMALE.rawValue) != 0
        isVideoTx = (user.uUserState & USERSTATE_VIDEOCAPTURE.rawValue) != 0
        isDesktopTx = (user.uUserState & USERSTATE_DESKTOP.rawValue) != 0
        isStreamingMedia = (user.uUserState & USERSTATE_MEDIAFILE.rawValue) != 0
    }

    func applyStatus() {
        var mode = selectedMode.ttMode
        if isFemale {
            mode |= StatusMode.STATUSMODE_FEMALE.rawValue
        }
        TeamTalkClient.shared.changeStatus(mode: INT32(mode), message: statusMessage)

        UserDefaults.standard.set(statusMessage, forKey: "user_status_message")
    }

    func handleTTMessage(_ m: TTMessage) {
        switch m.nClientEvent {
        case CLIENTEVENT_CMD_USER_UPDATE,
            CLIENTEVENT_USER_STATECHANGE:
            if TeamTalkMessagePayload.user(from: m).nUserID == TeamTalkClient.shared.myUserID {
                refreshCurrentStatus()
            }
        default:
            break
        }
    }
}
