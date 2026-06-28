import SwiftUI

struct ServerManagementView: View {
    @ObservedObject var model: ServerManagementViewModel

    var body: some View {
        List {
            serverPropertiesSection

            if model.isAdmin {
                userAccountsSection
                banListSection
            }
        }
        .navigationTitle(model.title)
        .refreshable {
            model.refreshAll()
        }
        .onAppear {
            model.refreshAll()
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

    private var serverPropertiesSection: some View {
        Section("Server Statistics") {
            StatRow(title: "Online Users", value: "\(model.serverStats.totalUsers)")
            StatRow(title: "Total Channels", value: "\(model.serverStats.totalChannels)")
            StatRow(title: "Uptime", value: model.serverStats.uptime)
            StatRow(title: "Files", value: "-")
        }
    }

    private var userAccountsSection: some View {
        Section("User Accounts") {
            if model.userAccounts.isEmpty {
                Text("No user accounts")
                    .foregroundStyle(.secondary)
            }
            ForEach(model.userAccounts) { account in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(account.username)
                            .font(.body)
                        Text(account.userType)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Kick") {
                        model.kickUser(userID: account.id)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    Button("Ban") {
                        model.banUser(userID: account.id)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundStyle(.red)
                }
            }
        }
    }

    private var banListSection: some View {
        Section("Banned Users") {
            if model.banEntries.isEmpty {
                Text("No banned users")
                    .foregroundStyle(.secondary)
            }
            ForEach(model.banEntries) { ban in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ban.username)
                            .font(.body)
                        Text(ban.ipAddress)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Remove") {
                        model.removeBan(ipAddress: ban.ipAddress)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }
}

private struct StatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}
