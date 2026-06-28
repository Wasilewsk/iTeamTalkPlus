import SwiftUI
import UIKit

struct MainTabView: View {
    @ObservedObject var model: MainTabModel
    let close: () -> Void
    @State private var saveAlertName = String(localized: "New Server", comment: "Dialog message")
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // 0 - Channels
            ChannelsTabView(mainModel: model, model: model.channelListModel, close: close)
                .tabItem {
                    Label("Channels", systemImage: "list.bullet.rectangle")
                }
                .tag(0)

            // 1 - Channel Messages
            NavigationStack {
                TextMessageView(model: model.channelChatModel)
            }
            .tabItem {
                Label("Chat", systemImage: "message.fill")
            }
            .tag(1)

            // 2 - Global Chat
            NavigationStack {
                GlobalChatView(model: model.globalChatModel)
            }
            .tabItem {
                Label("Global", systemImage: "megaphone.fill")
            }
            .tag(2)

            // 3 - Private Messages
            NavigationStack {
                PrivateMessagesView(model: model.privateMessagesModel)
            }
            .tabItem {
                Label("Private", systemImage: "envelope.fill")
            }
            .tag(3)

            // 4 - Media Streams
            NavigationStack {
                MediaStreamingView(model: model.mediaStreamingModel)
            }
            .tabItem {
                Label("Media", systemImage: "antenna.radiowaves.left.and.right")
            }
            .tag(4)

            // 5 - Files
            NavigationStack {
                FileManagementView(model: model.fileManagementModel)
            }
            .tabItem {
                Label("Files", systemImage: "folder.fill")
            }
            .tag(5)

            // 6 - Server Management
            NavigationStack {
                ServerManagementView(model: model.serverManagementModel)
            }
            .tabItem {
                Label("Manage", systemImage: "gearshape.2.fill")
            }
            .tag(6)

            // 7 - Online Users
            NavigationStack {
                OnlineUsersView(model: model.onlineUsersModel)
            }
            .tabItem {
                Label("Users", systemImage: "person.3.fill")
            }
            .tag(7)

            // 8 - Connection Status
            NavigationStack {
                ConnectionStatusView(model: model.connectionStatusModel)
            }
            .tabItem {
                Label("Status", systemImage: "chart.bar.fill")
            }
            .tag(8)

            // 9 - Event History
            NavigationStack {
                EventHistoryView(model: model.eventHistoryModel)
            }
            .tabItem {
                Label("Events", systemImage: "clock.arrow.circlepath")
            }
            .tag(9)

            // 10 - Manage Status
            NavigationStack {
                ManageStatusView(model: model.manageStatusModel)
            }
            .tabItem {
                Label("My Status", systemImage: "person.crop.circle.badge.checkmark")
            }
            .tag(10)

            // 11 - Preferences
            NavigationStack {
                PreferencesView(model: model.preferencesModel)
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(11)
        }
        .accessibilityAction(.magicTap) {
            model.channelListModel.txBtnAccessibilityAction()
        }
        .onAppear {
            model.setup()
            model.onVisibleAppear()
        }
        .onDisappear {
            model.teardown()
        }
        .onReceive(NotificationCenter.default.publisher(for: .iTeamTalkRemoteControl)) { notification in
            model.remoteControl(notification.object as? UIEvent)
        }
        .alert("Error",
               isPresented: Binding(
                get: { model.alertMessage != nil },
                set: { if !$0 { model.alertMessage = nil } }
               )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.alertMessage ?? "")
        }
        .alert("Connect to Server",
            isPresented: Binding(
                get: { model.fatalAlertMessage != nil },
                set: { if !$0 { model.fatalAlertMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                close()
            }
        } message: {
            Text(model.fatalAlertMessage ?? "")
        }
        .alert("Save Server",
            isPresented: $model.showSaveAlert
        ) {
            TextField("New Server",
                text: $saveAlertName
            )
            Button("No", role: .cancel) {
                model.skipSaveAndDisconnect()
            }
            Button("Yes") {
                model.saveAndDisconnect(name: saveAlertName)
            }
        } message: {
            Text("Save server to server list?")
        }
    }
}

// MARK: - Channels tab

private struct ChannelsTabView: View {
    @ObservedObject var mainModel: MainTabModel
    @ObservedObject var model: ChannelListModel
    let close: () -> Void

    var body: some View {
        NavigationStack(path: $model.navigationPath) {
            ChannelListContainerView(model: model)
                .navigationDestination(for: ChannelListDestination.self) { destination in
                    channelDestinationView(destination)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Disconnect") {
                            mainModel.disconnectTapped(dismiss: close)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            model.showNewChannel()
                        } label: {
                            Image(systemName: "plus")
                                .accessibilityLabel("Create new channel")
                        }
                    }
                }
                .sheet(item: $model.channelDetailModel) { detailModel in
                    ChannelDetailSheetView(model: detailModel)
                        .presentationDragIndicator(.visible)
                }
        }
    }

    @ViewBuilder
    private func channelDestinationView(_ destination: ChannelListDestination) -> some View {
        switch destination {
        case .userDetail(let m):
            UserDetailView(model: m)
        case .textMessage(let m):
            TextMessageView(model: m)
        }
    }
}

// MARK: - Channel detail sheet

private struct ChannelDetailSheetView: View {
    @ObservedObject var model: ChannelDetailModel

    var body: some View {
        NavigationStack {
            ChannelDetailView(model: model, setupCodec: {
                model.audioCodecModel = model.makeAudioCodecModel()
            })
            .navigationDestination(isPresented: Binding(
                get: { model.audioCodecModel != nil },
                set: { if !$0 { model.audioCodecModel = nil } }
            )) {
                if let codecModel = model.audioCodecModel {
                    AudioCodecView(model: codecModel, performAction: { action in
                        model.applyCodecAction(action, codecModel: codecModel)
                    })
                }
            }
        }
    }
}
