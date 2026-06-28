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

final class FileManagementViewModel: ObservableObject, TeamTalkEvent {
    @Published var files = [FileEntry]()
    @Published var activeTransfers = [FileTransferEntry]()
    @Published var isLoading = false
    @Published var errorMessage: String?

    let title: String

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

        let fileList = TeamTalkClient.shared.getChannelFiles(channelID: myChannelID)
        files = fileList.map { file in
            FileEntry(
                id: file.nFileID,
                filename: String(cString: file.szFileName),
                filesize: file.nFileSize,
                username: String(cString: file.szUsername),
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

        let fileID = TeamTalkClient.shared.doSendFile(channelID: myChannelID, localFilePath: url.path)
        if fileID > 0 {
            let entry = FileTransferEntry(id: Int(fileID), filename: url.lastPathComponent, progress: 0, isUpload: true)
            activeTransfers.append(entry)
        }
    }

    func downloadFile(_ file: FileEntry) {
        let myChannelID = TeamTalkClient.shared.myChannelID
        guard myChannelID > 0 else { return }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let localPath = documentsPath.appendingPathComponent(file.filename).path

        let transferID = TeamTalkClient.shared.doRecvFile(channelID: myChannelID, fileID: file.remoteFileID, localFilePath: localPath)
        if transferID > 0 {
            let entry = FileTransferEntry(id: Int(transferID), filename: file.filename, progress: 0, isUpload: false)
            activeTransfers.append(entry)
        }
    }

    func deleteFile(_ file: FileEntry) {
        let myChannelID = TeamTalkClient.shared.myChannelID
        guard myChannelID > 0 else { return }
        TeamTalkClient.shared.doDeleteFile(channelID: myChannelID, fileID: file.remoteFileID)
        refreshFiles()
    }

    func handleTTMessage(_ m: TTMessage) {
        switch m.nClientEvent {
        case CLIENTEVENT_CMD_FILE_NEW,
            CLIENTEVENT_CMD_FILE_REMOVE:
            refreshFiles()

        case CLIENTEVENT_FILETRANSFER:
            let transfer = TeamTalkMessagePayload.fileTransfer(from: m)
            if let idx = activeTransfers.firstIndex(where: { $0.id == Int(transfer.nTransferID) }) {
                let progress = transfer.nFileSize > 0 ? Double(transfer.nTransferred) / Double(transfer.nFileSize) : 0
                activeTransfers[idx] = FileTransferEntry(
                    id: Int(transfer.nTransferID),
                    filename: String(cString: transfer.szRemoteFileName),
                    progress: progress,
                    isUpload: !transfer.bInbound
                )
            }
            if transfer.nStatus == FILETRANSFER_FINISHED || transfer.nStatus == FILETRANSFER_ERROR {
                activeTransfers.removeAll { $0.id == Int(transfer.nTransferID) }
                refreshFiles()
            }

        default:
            break
        }
    }
}
