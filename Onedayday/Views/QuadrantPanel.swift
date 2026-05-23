import SwiftUI
import UniformTypeIdentifiers

struct QuadrantPanel: View {
    @EnvironmentObject var vm: TodoViewModel
    @EnvironmentObject var loc: LocalizationManager
    @EnvironmentObject var svm: SettingsViewModel
    let quadrant: TodoItem.Quadrant
    let date: String
    let showCompleted: Bool

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ──
            HStack(spacing: 6) {
                Circle()
                    .fill(quadrantColor)
                    .frame(width: 7, height: 7)
                Text(loc.qName(quadrant))
                    .font(.system(size: 12, weight: .semibold, design: .default))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(tasks.count)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            Divider().opacity(0.3)

            // ── Task list ──
            ScrollView {
                LazyVStack(spacing: 0) {
                    if tasks.isEmpty {
                        Text(emptyText)
                            .font(.system(size: 11)).foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center).frame(maxWidth: .infinity)
                            .padding(.top, 28)
                    }
                    ForEach(tasks) { item in
                        TaskRowView(item: item)
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
            .onDrop(of: [.plainText], isTargeted: nil) { providers in
                handleDrop(providers: providers)
            }

            // ── Add button ──
            Divider().opacity(0.3)
            Button {
                vm.sheetConfig = SheetConfig(date: date, quadrant: quadrant)
            } label: {
                Label(loc.t("add_task"), systemImage: "plus.circle")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.plain)
        }
        .frame(minWidth: 220, minHeight: 200)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(quadrantColor.opacity(0.25), lineWidth: 0.8)
        )
    }

    private var tasks: [TodoItem] {
        vm.tasks(for: quadrant, date: date, showCompleted: showCompleted)
    }

    private var emptyText: String {
        switch quadrant {
        case .importantUrgent:       return loc.t("empty_q1")
        case .importantNotUrgent:    return loc.t("empty_q2")
        case .notImportantUrgent:    return loc.t("empty_q3")
        case .notImportantNotUrgent: return loc.t("empty_q4")
        }
    }

    private var quadrantColor: Color { quadrant.themeColor }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { data, _ in
                if let data = data as? Data, let id = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        vm.moveItem(id: id, toDate: date, toQuadrant: quadrant)
                    }
                }
            }
        }
        return true
    }
}
