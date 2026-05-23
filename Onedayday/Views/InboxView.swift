import SwiftUI

struct InboxView: View {
    @EnvironmentObject var vm: TodoViewModel
    @EnvironmentObject var loc: LocalizationManager
    @EnvironmentObject var svm: SettingsViewModel
    @State private var quickText: String = ""
    @State private var showAddSheet = false

    var body: some View {
        VStack(spacing: 0) {
            // ── Quick capture bar ──
            HStack(spacing: 8) {
                TextField(loc.t("inbox_placeholder"), text: $quickText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13))
                    .onSubmit { commitQuick() }

                Button(action: commitQuick) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .disabled(quickText.trimmingCharacters(in: .whitespaces).isEmpty)

                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(loc.t("new_task"))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)

            Divider().opacity(0.3)

            // ── Inbox items ──
            let items = vm.inboxItems
            if items.isEmpty {
                VStack(spacing: 6) {
                    Text(loc.t("empty_inbox"))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 60)
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(items) { item in
                            TaskRowView(item: item)
                                .onDrag {
                                    NSItemProvider(object: item.id as NSString)
                                }
                        }
                    }
                    .padding(.vertical, 6)
                }
                .scrollIndicators(.hidden)
            }

            Spacer()
        }
        .background(.ultraThinMaterial)
        .sheet(isPresented: $showAddSheet) {
            AddTaskSheet(date: nil)
        }
    }

    private func commitQuick() {
        let trimmed = quickText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let item = TodoItem(
            name: trimmed,
            device: "Mac",
            date: nil,
            createdDate: TodoViewModel.today,
            important: false,
            urgent: false,
            completed: false
        )
        vm.add(item)
        quickText = ""
    }
}
