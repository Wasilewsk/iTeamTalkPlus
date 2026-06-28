import SwiftUI
import TeamTalkKit

func remoteFileName(_ file: RemoteFile) -> String {
    withUnsafePointer(to: file.szFileName) {
        String(cString: UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self))
    }
}

func remoteFileUsername(_ file: RemoteFile) -> String {
    withUnsafePointer(to: file.szUsername) {
        String(cString: UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self))
    }
}

func fileTransferFileName(_ transfer: FileTransfer) -> String {
    withUnsafePointer(to: transfer.szRemoteFileName) {
        String(cString: UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self))
    }
}

struct FileEntry: Identifiable {
    let id: Int
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
        files = fileList.enumerated().map { index, file in
            FileEntry(
                id: index,
                filename: remoteFileName(file),
                filesize: file.nFileSize,
                username: remoteFileUsername(file),
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
        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = String(localized: "Cannot access file", comment: "files")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
        do {
            if FileManager.default.fileExists(atPath: tempURL.path) {
                try FileManager.default.removeItem(at: tempURL)
            }
            try FileManager.default.copyItem(at: url, to: tempURL)
        } catch {
            errorMessage = String(localized: "Failed to access file", comment: "files")
            return
        }
        let transferID = TeamTalkClient.shared.doSendFile(channelID: myChannelID, localFilePath: tempURL.path)
        if transferID <= 0 {
            errorMessage = String(localized: "Failed to start upload", comment: "files")
        }
    }

    func downloadFile(_ file: FileEntry) {
        let myChannelID = TeamTalkClient.shared.myChannelID
        guard myChannelID > 0 else { return }
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let localPath = documentsPath.appendingPathComponent(file.filename).path
        let transferID = TeamTalkClient.shared.doRecvFile(channelID: myChannelID, fileID: file.remoteFileID, localFilePath: localPath)
        _ = transferID
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
            let transferID = Int(transfer.nTransferID)
            let isUpload = transfer.bInbound == 0
            let progress = transfer.nFileSize > 0 ? Double(transfer.nTransferred) / Double(transfer.nFileSize) : 0
            let filename = fileTransferFileName(transfer)
            if let idx = activeTransfers.firstIndex(where: { $0.id == transferID }) {
                activeTransfers[idx] = FileTransferEntry(
                    id: transferID,
                    filename: filename,
                    progress: progress,
                    isUpload: isUpload
                )
            } else if transfer.nStatus != FILETRANSFER_FINISHED && transfer.nStatus != FILETRANSFER_ERROR {
                activeTransfers.append(FileTransferEntry(
                    id: transferID,
                    filename: filename,
                    progress: progress,
                    isUpload: isUpload
                ))
            }
            if transfer.nStatus == FILETRANSFER_FINISHED || transfer.nStatus == FILETRANSFER_ERROR {
                activeTransfers.removeAll { $0.id == transferID }
                refreshFiles()
            }
        default:
            break
        }
    }
}
