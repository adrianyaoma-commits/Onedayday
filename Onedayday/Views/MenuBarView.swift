import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var vm: TodoViewModel
    @EnvironmentObject var loc: LocalizationManager
    @EnvironmentObject var svm: SettingsViewModel
    @State private var newBtnHovered = false
    @State private var hoveredTaskId: String?
    @State private var quitBtnHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Header + new task button ──
            HStack {
                Button {
                    vm.triggerAddSheet = true
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 12))
                        Text(loc.t("menubar_new"))
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(newBtnHovered ? Color.blue.opacity(0.18) : Color.blue.opacity(0.08))
                    )
                    .scaleEffect(newBtnHovered ? 1.03 : 1.0)
                }
                .buttonStyle(.plain)
                .onHover { h in withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { newBtnHovered = h } }

                Spacer()

                Text(loc.t("menubar_hint"))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 6)

            Divider()

            Text(loc.t("all_today_tasks"))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 12)
                .padding(.top, 6)
                .padding(.bottom, 2)

            let tasks = vm.todayAllTasksSorted
            if tasks.isEmpty {
                Text(loc.t("menu_empty"))
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .padding(12)
            } else {
                ForEach(tasks.prefix(10)) { item in
                    Button {
                        vm.toggleComplete(item)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 12))
                                .foregroundStyle(item.completed ? .green : quadrantColor(for: item))
                                .contentTransition(.symbolEffect(.replace))

                            VStack(alignment: .leading, spacing: 1) {
                                Text(loc.presetName(for: item))
                                    .font(.system(size: 12, weight: .medium))
                                    .lineLimit(1)
                                    .foregroundStyle(.primary)
                            }
                        }
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(hoveredTaskId == item.id ? Color.primary.opacity(0.08) : Color.clear)
                        )
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 2)
                    .onHover { h in
                        withAnimation(.easeInOut(duration: 0.15)) { hoveredTaskId = h ? item.id : nil }
                    }
                }

                if tasks.count > 10 {
                    Text(String(format: loc.t("more_overflow"), tasks.count - 10))
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 12)
                }
            }

            Divider()

            HStack {
                Text("\(loc.t("active_count_label")): \(vm.activeCount(for: TodoViewModel.today))")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                Spacer()
                Button(loc.t("quit")) { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundStyle(quitBtnHovered ? .primary : .secondary)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(quitBtnHovered ? Color.primary.opacity(0.08) : Color.clear)
                    )
                    .onHover { h in
                        withAnimation(.easeInOut(duration: 0.15)) { quitBtnHovered = h }
                    }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .frame(width: 250)
    }

    private func quadrantColor(for item: TodoItem) -> Color { item.quadrant.themeColor }
}
