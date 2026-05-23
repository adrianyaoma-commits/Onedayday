import SwiftUI

struct HeatmapView: View {
    @EnvironmentObject var vm: TodoViewModel
    @EnvironmentObject var loc: LocalizationManager

    private let columns = 20
    @State private var hoveredIndex: Int?

    var body: some View {
        let data = vm.heatmapData()
        let totalCompleted = data.reduce(0) { $0 + $1.count }
        let bestDay = data.max(by: { $0.count < $1.count })
        let activeDays = data.filter { $0.count > 0 }.count

        VStack(spacing: 0) {
            Text(loc.t("heatmap_title"))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider().opacity(0.15).padding(.vertical, 12)

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(14), spacing: 3), count: columns),
                spacing: 3
            ) {
                ForEach(data.indices, id: \.self) { idx in
                    let entry = data[idx]
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorFor(count: entry.count))
                        .frame(width: 14, height: 14)
                        .scaleEffect(hoveredIndex == idx ? 1.6 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: hoveredIndex)
                        .onHover { hovering in
                            hoveredIndex = hovering ? idx : nil
                        }
                        .popover(isPresented: Binding(
                            get: { hoveredIndex == idx },
                            set: { if !$0 { hoveredIndex = nil } }
                        ), arrowEdge: .bottom) {
                            let (emoji, vibe) = dopamine(for: entry.count)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(emoji)  \(formatDate(entry.date))")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                Text("\(entry.count) \(loc.t("heatmap_total_completed").lowercased())")
                                    .font(.system(size: 12)).foregroundStyle(.secondary)
                                Text(vibe)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.teal)
                            }
                            .padding(12)
                            .frame(width: 180)
                        }
                }
            }

            Divider().opacity(0.15).padding(.vertical, 12)

            HStack(spacing: 24) {
                statBlock(value: "\(totalCompleted)", label: loc.t("heatmap_total_completed"))
                statBlock(value: "\(activeDays)", label: loc.t("heatmap_active_days"))
                if let best = bestDay, best.count > 0 {
                    statBlock(value: formatDate(best.date), label: "\(loc.t("heatmap_best_day")) (\(best.count))")
                }
                statBlock(value: "\(totalCompleted > 0 && activeDays > 0 ? String(format: "%.1f", Double(totalCompleted)/Double(activeDays)) : "0")", label: loc.t("heatmap_avg_day"))
            }.frame(maxWidth: .infinity)

            Divider().opacity(0.15).padding(.vertical, 12)

            HStack(spacing: 4) {
                Text(loc.t("heatmap_less")).font(.system(size: 13, weight: .regular)).foregroundStyle(.secondary)
                ForEach([0, 1, 2, 4, 6], id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2).fill(colorFor(count: level)).frame(width: 10, height: 10)
                }
                Text(loc.t("heatmap_more")).font(.system(size: 13, weight: .regular)).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 24).padding(.vertical, 20)
        .frame(minWidth: 480, maxWidth: 560, minHeight: 360, maxHeight: 520)
        .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Dopamine copy
    private func dopamine(for count: Int) -> (emoji: String, text: String) {
        switch count {
        case 0:  return ("😴", loc.t("dopamine_0"))
        case 1:  return ("💧", loc.t("dopamine_1"))
        case 2:  return ("✌️", loc.t("dopamine_2"))
        case 3...4: return ("🔥", loc.t("dopamine_34"))
        case 5...7: return ("🚀", loc.t("dopamine_57"))
        default:  return ("👑", loc.t("dopamine_max"))
        }
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 13, weight: .semibold, design: .rounded)).monospacedDigit()
            Text(label).font(.system(size: 13, weight: .regular)).foregroundStyle(.secondary)
        }
    }

    private func formatDate(_ iso: String) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX")
        guard let d = f.date(from: iso) else { return iso }
        let out = DateFormatter(); out.dateFormat = "MMM d"; out.locale = Locale(identifier: "en_US")
        return out.string(from: d)
    }

    private func colorFor(count: Int) -> Color {
        switch count {
        case 0:  return .gray.opacity(0.15)
        case 1:  return .green.opacity(0.25)
        case 2:  return .green.opacity(0.4)
        case 3...4: return .green.opacity(0.6)
        case 5...7: return .green.opacity(0.8)
        default: return .green
        }
    }
}
