import SwiftUI

struct EventHistoryView: View {
    @ObservedObject var model: EventHistoryViewModel

    var body: some View {
        List {
            if model.events.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No Events")
                        .font(.title2)
                    Text("Server events will appear here")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
            ForEach(model.events.indices, id: \.self) { index in
                let event = model.events[index]
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: iconName(for: event.message))
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.message)
                            .font(.body)
                        Text(event.date, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
        .navigationTitle(model.title)
    }

    private func iconName(for message: String) -> String {
        if message.contains("logged on") || message.contains("logged off") {
            return "person.circle"
        } else if message.contains("joined") || message.contains("left") {
            return "arrow.right.circle"
        } else if message.contains("Connected") || message.contains("Connection lost") || message.contains("Connection failed") {
            return "antenna.radiowaves.left.and.right"
        } else if message.contains("kicked") {
            return "exclamationmark.triangle"
        } else if message.contains("created") || message.contains("removed") {
            return "folder"
        }
        return "info.circle"
    }
}
