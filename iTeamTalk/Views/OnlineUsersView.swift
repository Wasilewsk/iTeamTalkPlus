import SwiftUI

struct OnlineUsersView: View {
    @ObservedObject var model: OnlineUsersViewModel

    var body: some View {
        List {
            if model.filteredUsers.isEmpty && !model.searchText.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("No users match your search")
                )
            }

            ForEach(model.filteredUsers) { entry in
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Circle()
                                .fill(entry.isTalking ? Color.green : (entry.isMuted ? Color.red : Color.gray))
                                .frame(width: 8, height: 8)
                            Text(entry.nickname)
                                .font(.body)
                                .lineLimit(1)
                        }
                        Text(entry.channelName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        if entry.isVideoTx {
                            Image(systemName: "video.fill")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        if entry.isDesktopTx {
                            Image(systemName: "desktopcomputer")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        if entry.isMediaFileTx {
                            Image(systemName: "music.note")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    model.showUserDetail(userID: entry.id)
                }
            }
        }
        .navigationTitle(model.title)
        .searchable(text: $model.searchText, prompt: "Search users")
        .refreshable {
            model.refreshUsers()
        }
        .onAppear {
            model.refreshUsers()
        }
    }
}
