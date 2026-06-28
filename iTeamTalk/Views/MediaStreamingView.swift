import SwiftUI

struct MediaStreamingView: View {
    @ObservedObject var model: MediaStreamingViewModel

    var body: some View {
        List {
            if model.streamGroups.isEmpty {
                ContentUnavailableView(
                    "No Active Streams",
                    systemImage: "antenna.radiowaves.left.and.right",
                    description: Text("Active media streams will appear here")
                )
            }
            ForEach(model.streamGroups) { group in
                Section(group.username) {
                    ForEach(group.streams) { stream in
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
            }
        }
        .navigationTitle(model.title)
        .refreshable {
            model.refreshStreams()
        }
        .onAppear {
            model.refreshStreams()
        }
    }
}
