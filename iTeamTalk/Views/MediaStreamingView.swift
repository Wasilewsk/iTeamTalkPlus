import SwiftUI
import UniformTypeIdentifiers

struct MediaStreamingView: View {
    @ObservedObject var model: MediaStreamingViewModel
    @State private var showMediaPicker = false

    var body: some View {
        streamList
            .navigationTitle(model.title)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if model.isStreamingLocalFile {
                            Button(role: .destructive) {
                                model.stopStreamingLocalFile()
                            } label: {
                                Image(systemName: "stop.circle.fill")
                            }
                            .accessibilityLabel("Stop streaming media file")
                        }
                        Button {
                            showMediaPicker = true
                        } label: {
                            Image(systemName: "music.note.list")
                        }
                        .accessibilityLabel(model.isStreamingLocalFile ? "Change media file" : "Stream a media file")
                    }
                }
            }
            .refreshable {
                model.refreshStreams()
            }
            .onAppear {
                model.refreshStreams()
            }
            .fileImporter(
                isPresented: $showMediaPicker,
                allowedContentTypes: [.audio, .movie, .video, .mpeg4Movie, .appleProtectedMPEG4Audio, .wav, .mp3],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    model.startStreamingLocalFile(at: url)
                }
            }
    }

    private var streamList: some View {
        List {
            if model.streamGroups.isEmpty {
                emptyStreams
            }
            streamSections
        }
    }

    private var emptyStreams: some View {
        VStack(spacing: 8) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No Active Streams")
                .font(.title2)
            Text("Active media streams will appear here")
                .font(.body)
                .foregroundStyle(.secondary)
            Text("Use the toolbar button to stream a file")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .accessibilityLabel("No active streams. Use the stream button in the toolbar to stream a media file.")
    }

    private var streamSections: some View {
        ForEach(model.streamGroups) { group in
            Section(group.username) {
                ForEach(group.streams) { stream in
                    streamRow(stream)
                }
            }
        }
    }

    private func streamRow(_ stream: MediaStreamEntry) -> some View {
        HStack {
            Image(systemName: stream.iconName)
                .frame(width: 24)
                .foregroundStyle(.blue)
            Text(stream.streamType)
            Spacer()
            Button("Stop") {
                model.stopStream(for: stream.userID)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.red)
            .accessibilityLabel("Stop \(stream.streamType) for user \(stream.userID)")
        }
        .accessibilityLabel("\(stream.streamType) stream for user \(stream.userID)")
        .accessibilityAddTraits(.isButton)
    }
}
