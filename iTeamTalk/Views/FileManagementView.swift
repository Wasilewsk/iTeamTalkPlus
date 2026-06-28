import SwiftUI
import UniformTypeIdentifiers

struct FileManagementView: View {
    @ObservedObject var model: FileManagementViewModel
    @State private var showFilePicker = false

    var body: some View {
        List {
            if !model.activeTransfers.isEmpty {
                Section("Active Transfers") {
                    ForEach(model.activeTransfers) { transfer in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: transfer.isUpload ? "arrow.up.doc" : "arrow.down.doc")
                                    .foregroundStyle(transfer.isUpload ? .orange : .blue)
                                Text(transfer.filename)
                                    .lineLimit(1)
                            }
                            ProgressView(value: transfer.progress)
                                .tint(transfer.isUpload ? .orange : .blue)
                        }
                        .accessibilityLabel(transfer.isUpload ? "Uploading \(transfer.filename)" : "Downloading \(transfer.filename)")
                        .accessibilityValue("\(Int(transfer.progress * 100)) percent complete")
                    }
                }
            }

            Section("Channel Files") {
                if model.files.isEmpty {
                    Text("No files in this channel")
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("No files available")
                }
                ForEach(model.files) { file in
                    HStack {
                        Image(systemName: "doc.fill")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(file.filename)
                                .lineLimit(1)
                            Text(fileSizeString(file.filesize))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Download") {
                            model.downloadFile(file)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .accessibilityLabel("Download \(file.filename)")
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        model.downloadFile(file)
                    }
                    .accessibilityLabel("\(file.filename), \(fileSizeString(file.filesize))")
                    .accessibilityAddTraits(.isButton)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            model.deleteFile(file)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .accessibilityLabel("Delete \(file.filename)")
                    }
                }
            }
        }
        .navigationTitle(model.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showFilePicker = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Upload file")
            }
        }
        .refreshable {
            model.refreshFiles()
        }
        .onAppear {
            model.refreshFiles()
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.data, .image, .movie, .audio, .video, .pdf, .text],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                model.uploadFile(at: url)
            }
        }
        .alert("Error", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private func fileSizeString(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}
