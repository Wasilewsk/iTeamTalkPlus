import SwiftUI

struct GlobalChatView: View {
    @ObservedObject var model: GlobalChatViewModel
    @FocusState private var isComposing: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                List {
                    ForEach(model.messages.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(model.messages[index].nickname)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(model.messages[index].message)
                                .font(.body)
                                .textSelection(.enabled)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
                .onChange(of: model.messages.count) { _ in
                    scrollToBottom(proxy)
                }
            }

            Divider()

            HStack(alignment: .bottom, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $model.composedText)
                        .focused($isComposing)
                        .frame(minHeight: 40, maxHeight: 96)
                        .accessibilityLabel("Message")

                    if model.composedText.isEmpty {
                        Text("Broadcast to all users...")
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 8)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
                Button("Send") {
                    model.sendMessage()
                    isComposing = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.bar)
        }
        .navigationTitle(model.title)
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard !model.messages.isEmpty else { return }
        let idx = model.messages.count - 1
        DispatchQueue.main.async {
            proxy.scrollTo(idx, anchor: .bottom)
        }
    }
}
