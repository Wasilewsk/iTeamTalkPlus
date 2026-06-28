import SwiftUI
import TeamTalkKit

struct ConnectionStatusView: View {
    @ObservedObject var model: ConnectionStatusViewModel

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Status")
                    Spacer()
                    Text(model.connectionState)
                        .foregroundStyle(model.connectionState == "Online" ? .green : .red)
                        .fontWeight(.semibold)
                }
                HStack {
                    Text("Server")
                    Spacer()
                    Text(model.serverName)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Connection")
            }

            Section {
                HStack {
                    Text("User ID")
                    Spacer()
                    Text("#\(model.myUserID)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Username")
                    Spacer()
                    Text(model.myUsername)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Channel")
                    Spacer()
                    Text(model.myChannel)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("My Info")
            }
        }
        .navigationTitle(model.title)
    }
}
