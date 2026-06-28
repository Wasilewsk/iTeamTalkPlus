import SwiftUI
import TeamTalkKit

struct FileEntry: Identifiable {
    let id: INT32
    let filename: String
    let filesize: Int64
    let username: String
    let remoteFileID: INT32
}

struct FileTransferEntry: Identifiable {
    let id: Int
    let filename: String
    let progress: Double
    let isUpload: Bool
}

final class FileManagementViewModel: ObservableObject {
    @Published var files = [FileEntry]()
    @Published var activeTransfers = [FileTransferEntry]()
    @Published var isLoading = false
    @Published var errorMessage: String?

    let title: String

    private var transferIDCounter = 0

    init(title: String = String(localized: "Files", comment: "tab")) {
        self.title = title
        addToTTMessages(self)
    }

    deinit {
        removeAllTTMessageHandlers()
    }

    func refreshFiles() {
        isLoading = true
        let myChannelID = TeamTalkClient.shared.myChannelID
        guard myChannelID > 0 else {
            isLoading = false
            files = []
            return
        }

        let fileList = TeamTalkClient.shared.getFiles(channelID: myChannelID)
        files = fileList.map { file in
            FileEntry(
                id: file.nFileID,
                filename: TeamTalkString.file(.name, from: file),
                filesize: file.nFileSize,
                username: TeamTalkString.file(.username, from: file),
                remoteFileID: file.nFileID
            )
        }
        isLoading = false
    }

    func uploadFile(at url: URL) {
        let myChannelID = TeamTalkClient.shared.myChannelID
        guard myChannelID > 0 else {
            errorMessage = String(localized: "Not connected to a channel", comment: "files")
            return
        }

        let fileID = TeamTalkClient.shared.uploadFile(channelID: myChannelID, localFilePath: url.path)
        if fileID > 0 {
            let entry = FileTransferEntry(id: transferIDCounter, filename: url.lastPathComponent, progress: 0, isUpload: true)
            activeTransfers.append(entry)
            transferIDCounter += 1
        }
    }

    func downloadFile(_ file: FileEntry) {
        let myChannelID = TeamTalkClient.shared.myChannelID
        guard myChannelID > 0 else { return }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let localPath = documentsPath.appendingPathComponent(file.filename).path

        let transferID = TeamTalkClient.shared.downloadFile(channelID: myChannelID, remoteFileID: file.remoteFileID, localFilePath: localPath)
        if transferID > 0 {
            let entry = FileTransferEntry(id: transferIDCounter, filename: file.filename, progress: 0, isUpload: false)
            activeTransfers.append(entry)
            transferIDCounter += 1
        }
    }

    func deleteFile(_ file: FileEntry) {
        let myChannelID = TeamTalkClient.shared.myChannelID
        guard myChannelID > 0 else { return }
        TeamTalkClient.shared.deleteFile(channelID: myChannelID, remoteFileID: file.remoteFileID)
        refreshFiles()
    }
}

extension FileManagementViewModel: TeamTalkEvent {
    func handleTTMessage(_ m: TTMessage) {
        switch m.nClientEvent {
        case CLIENTEVENT_CMD_FILES_NEW,
            CLIENTEVENT_CMD_FILES_REMOVE,
            CLIENTEVENT_CMD_FILES_UPDATE:
            refreshFiles()

        case CLIENTEVENT_FILE_TRANSFER:
            let transfer = TeamTalkMessagePayload.transfer(from: m)
            if let idx = activeTransfers.firstIndex(where: { $0.id == Int(transfer.nTransferID) }) {
                let progress = transfer.nByteCount > 0 ? Double(transfer.nByteCount) / Double(transfer.nFileSize) : 0
                activeTransfers[idx] = FileTransferEntry(
                    id: Int(transfer.nTransferID),
                    filename: activeTransfers[idx].filename,
                    progress: progress,
                    isUpload: activeTransfers[idx].isUpload
                )
            }

        case CLIENTEVENT_FILE_TRANSFER_COMPLETE:
            let transfer = TeamTalkMessagePayload.transfer(from: m)
            activeTransfers.removeAll { $0.id == Int(transfer.nTransferID) }
            refreshFiles()

        default:
            break
        }
    }
}
