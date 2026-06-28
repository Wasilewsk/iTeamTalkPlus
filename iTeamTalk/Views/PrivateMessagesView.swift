import SwiftUI
import TeamTalkKit

struct PrivateMessagesView: View {
    @ObservedObject var model: PrivateMessagesViewModel

    var body: some View {
        Group {
            if let userID = model.selectedSession {
                PrivateChatDetailView(model: model, userID: userID)
            } else {
                sessionList
            }
        }
    }

    private var sessionList: some View {
        List {
            if model.sessions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "message")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No Private Messages")
                        .font(.title2)
                    Text("Private messages will appear here")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
            ForEach(model.sessions) { session in
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(getDisplayName(session.user))
                            .font(.body)
                            .lineLimit(1)
                        if let last = session.lastMessage {
                            Text(last.message)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    Spacer()
                    if session.unreadCount > 0 {
                        Text("\(session.unreadCount)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(Circle().fill(.red))
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    model.selectSession(session.id)
                }
            }
        }
        .navigationTitle(model.title)
        .toolbar(id: "pm") {
            ToolbarItem(id: "back", placement: .navigationBarLeading) {
                if model.selectedSession != nil {
                    Button("Back") {
                        model.selectedSession = nil
                    }
                }
            }
        }
    }
}

private struct PrivateChatDetailView: View {
    @ObservedObject var model: PrivateMessagesViewModel
    let userID: Int32
    @State private var text = ""
    @FocusState private var isComposing: Bool

    var body: some View {
        VStack(spacing: 0) {
            if let session = model.session(for: userID) {
                List {
                    Text(getDisplayName(session.user))
                        .font(.headline)
                }
                .listStyle(.plain)
            }

            Divider()

            HStack(alignment: .bottom, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .focused($isComposing)
                        .frame(minHeight: 40, maxHeight: 96)
                        .accessibilityLabel("Message")

                    if text.isEmpty {
                        Text("Type a private message...")
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 8)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
                Button("Send") {
                    model.sendMessage(to: userID, content: text)
                    text = ""
                    isComposing = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.bar)
        }
        .navigationTitle("Private Chat")
    }
}
