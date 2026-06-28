import SwiftUI

struct ManageStatusView: View {
    @ObservedObject var model: ManageStatusViewModel

    var body: some View {
        Form {
            Section("Status Mode") {
                Picker("Mode", selection: $model.selectedMode) {
                    ForEach(UserStatusMode.allCases, id: \.self) { mode in
                        Text(mode.localizedString).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Status Message") {
                TextField("Enter status message", text: $model.statusMessage)
            }

            Section("Flags") {
                Toggle(isOn: $model.isFemale) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Female Icon")
                        Text("Show female icon instead of male")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle(isOn: $model.isVideoTx) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Video Transmission")
                        Text("Stream webcam to channel")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle(isOn: $model.isDesktopTx) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Desktop Sharing")
                        Text("Share desktop to channel")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle(isOn: $model.isStreamingMedia) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Media File Streaming")
                        Text("Stream media file to channel")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Button("Apply Status") {
                    model.applyStatus()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .fontWeight(.semibold)
            }
        }
        .navigationTitle(model.title)
    }
}
