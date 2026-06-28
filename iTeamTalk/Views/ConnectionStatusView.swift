import SwiftUI

struct ConnectionStatusView: View {
    @ObservedObject var model: ConnectionStatusViewModel

    var body: some View {
        List {
            Section("Connection") {
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
                HStack {
                    Text("Address")
                    Spacer()
                    Text(model.serverIP)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Ping")
                    Spacer()
                    Text("\(model.pingMs) ms")
                        .foregroundStyle(.secondary)
                }
            }

            Section("My Info") {
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
            }

            Section("Bandwidth") {
                HStack {
                    Text("Received")
                    Spacer()
                    Text("\(model.rxBytes) bytes (\(String(format: "%.1f", model.rxKbps)) Kbps)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Sent")
                    Spacer()
                    Text("\(model.txBytes) bytes (\(String(format: "%.1f", model.txKbps)) Kbps)")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(model.title)
    }
}
