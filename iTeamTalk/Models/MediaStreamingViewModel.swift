import SwiftUI
import TeamTalkKit

struct MediaStreamGroup: Identifiable {
    let id: Int
    let username: String
    let streams: [MediaStreamEntry]
}

struct MediaStreamEntry: Identifiable {
    let id: Int
    let streamType: String
    let iconName: String
    let userID: INT32
}

final class MediaStreamingViewModel: ObservableObject, TeamTalkEvent {
    @Published var streamGroups = [MediaStreamGroup]()
    @Published var isStreamingLocalFile = false

    let title: String

    init(title: String = String(localized: "Media Streams", comment: "tab")) {
        self.title = title
        addToTTMessages(self)
    }

    deinit {
        removeAllTTMessageHandlers()
    }

    func stopStream(for userID: INT32) {
        let users = TeamTalkClient.shared.getServerUsers()
        if let user = users.first(where: { $0.nUserID == userID }) {
            if user.uUserState & USERSTATE_VOICE.rawValue != 0 {
                _ = TeamTalkClient.shared.unsubscribe(userID: userID, subscriptions: SUBSCRIBE_VOICE.rawValue)
            }
            if user.uUserState & USERSTATE_VIDEOCAPTURE.rawValue != 0 {
                _ = TeamTalkClient.shared.unsubscribe(userID: userID, subscriptions: SUBSCRIBE_VIDEOCAPTURE.rawValue)
            }
            if user.uUserState & USERSTATE_DESKTOP.rawValue != 0 {
                _ = TeamTalkClient.shared.unsubscribe(userID: userID, subscriptions: SUBSCRIBE_DESKTOP.rawValue)
            }
            if user.uUserState & USERSTATE_MEDIAFILE_AUDIO.rawValue != 0 || user.uUserState & USERSTATE_MEDIAFILE_VIDEO.rawValue != 0 {
                _ = TeamTalkClient.shared.unsubscribe(userID: userID, subscriptions: SUBSCRIBE_MEDIAFILE.rawValue)
            }
        }
        refreshStreams()
    }

    func startStreamingLocalFile(at url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        guard TeamTalkClient.shared.startStreamingMediaFileToChannel(filePath: url.path) else { return }
        isStreamingLocalFile = true
        refreshStreams()
    }

    func stopStreamingLocalFile() {
        TeamTalkClient.shared.stopStreamingMediaFileToChannel()
        isStreamingLocalFile = false
        refreshStreams()
    }

    func refreshStreams() {
        var byUser = [INT32: [MediaStreamEntry]]()
        var entryID = 0

        let users = TeamTalkClient.shared.getServerUsers()
        for user in users {
            var entries = [MediaStreamEntry]()

            if user.uUserState & USERSTATE_VOICE.rawValue != 0 {
                entries.append(MediaStreamEntry(id: entryID, streamType: "Voice", iconName: "mic.fill", userID: user.nUserID))
                entryID += 1
            }
            if user.uUserState & USERSTATE_VIDEOCAPTURE.rawValue != 0 {
                entries.append(MediaStreamEntry(id: entryID, streamType: "Video", iconName: "video.fill", userID: user.nUserID))
                entryID += 1
            }
            if user.uUserState & USERSTATE_MEDIAFILE.rawValue != 0 {
                entries.append(MediaStreamEntry(id: entryID, streamType: "Media File", iconName: "music.note", userID: user.nUserID))
                entryID += 1
            }
            if user.uUserState & USERSTATE_DESKTOP.rawValue != 0 {
                entries.append(MediaStreamEntry(id: entryID, streamType: "Desktop", iconName: "desktopcomputer", userID: user.nUserID))
                entryID += 1
            }

            if !entries.isEmpty {
                byUser[user.nUserID] = entries
            }
        }

        streamGroups = byUser.compactMap { userID, entries in
            let user = TeamTalkClient.shared.withUser(id: userID) { $0 }
            return MediaStreamGroup(id: Int(userID), username: getDisplayName(user), streams: entries)
        }
    }

    func handleTTMessage(_ m: TTMessage) {
        switch m.nClientEvent {
        case CLIENTEVENT_USER_STATECHANGE,
            CLIENTEVENT_CMD_USER_JOINED,
            CLIENTEVENT_CMD_USER_LEFT,
            CLIENTEVENT_CMD_USER_LOGGEDIN,
            CLIENTEVENT_CMD_USER_LOGGEDOUT:
            refreshStreams()
        case CLIENTEVENT_STREAM_MEDIAFILE,
            CLIENTEVENT_LOCAL_MEDIAFILE:
            if m.nClientEvent == CLIENTEVENT_LOCAL_MEDIAFILE {
                let info = TeamTalkMessagePayload.mediaFileInfo(from: m)
                isStreamingLocalFile = info.nStatus == MFS_STARTED || info.nStatus == MFS_PLAYING || info.nStatus == MFS_PAUSED
                if info.nStatus == MFS_FINISHED || info.nStatus == MFS_ERROR || info.nStatus == MFS_ABORTED || info.nStatus == MFS_CLOSED {
                    isStreamingLocalFile = false
                }
            }
            refreshStreams()
        default:
            break
        }
    }
}
