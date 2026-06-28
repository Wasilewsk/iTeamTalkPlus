import SwiftUI

struct MediaStreamingView: View {
    @ObservedObject var model: MediaStreamingViewModel

    var body: some View {
        streamList
            .navigationTitle(model.title)
            .refreshable {
                model.refreshStreams()
            }
            .onAppear {
                model.refreshStreams()
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
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
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
        }
    }
}
