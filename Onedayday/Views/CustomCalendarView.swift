import SwiftUI

struct CustomCalendarView: View {
    @EnvironmentObject var vm: TodoViewModel
    @EnvironmentObject var loc: LocalizationManager
    @Binding var selectedDate: Date
    @State private var displayMonth: Date
    @State private var hoveredDate: Date?

    private let cal = Calendar.current
    private let cellW: CGFloat = 28
    private let cellH: CGFloat = 30
    private let dotSize: CGFloat = 4

    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        self._displayMonth = State(initialValue: selectedDate.wrappedValue)
    }

    var body: some View {
        VStack(spacing: 2) {
            // ── Month/Year header ──
            HStack(spacing: 0) {
                Button(action: { withAnimation { changeMonth(-1) } }) {
                    Image(systemName: "chevron.left").font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                        .frame(width: 24, height: 24).contentShape(Rectangle())
                }.buttonStyle(.plain)
                Text(monthYearString).font(.system(size: 11, weight: .semibold)).foregroundStyle(.primary).frame(maxWidth: .infinity)
                Button(action: { withAnimation { changeMonth(1) } }) {
                    Image(systemName: "chevron.right").font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                        .frame(width: 24, height: 24).contentShape(Rectangle())
                }.buttonStyle(.plain)
            }.padding(.horizontal, 8).padding(.vertical, 4)

            // ── Weekday headers ──
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day).font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary).frame(width: cellW, height: 12)
                }
            }

            // ── Day grid ──
            let days = daysInMonth
            let offset = firstWeekdayOffset
            let totalCells = offset + days
            let rows = Int(ceil(Double(totalCells) / 7.0))
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { col in
                        let idx = row * 7 + col
                        if idx >= offset, idx < totalCells {
                            dayCell(day: idx - offset + 1)
                        } else {
                            Color.clear.frame(width: cellW, height: cellH)
                        }
                    }
                }
            }
        }
        .onChange(of: selectedDate) { _, newDate in
            if !cal.isDate(newDate, equalTo: displayMonth, toGranularity: .month) { displayMonth = newDate }
        }
    }

    // ── Day cell ──────────────────────────────────────────────────────────
    private func dayCell(day: Int) -> some View {
        let date = dateFor(day: day)
        let dateStr = TodoViewModel.dateString(from: date)
        let isToday = cal.isDateInToday(date)
        let isSelected = cal.isDate(date, inSameDayAs: selectedDate)
        let presence = vm.quadrantPresence(for: dateStr)

        let isHovered = hoveredDate.map { cal.isDate(date, inSameDayAs: $0) } ?? false
        return Button(action: { selectedDate = date }) {
            VStack(spacing: 0) {
                Text("\(day)").font(.system(size: 11, weight: isToday ? .bold : .regular, design: .rounded)).monospacedDigit()
                    .foregroundStyle(isSelected ? .white : (isToday ? .teal : .primary))
                    .frame(height: 16)
                HStack(spacing: 1.5) {
                    ForEach(TodoItem.Quadrant.allCases, id: \.self) { q in
                        Circle().fill(presence.contains(q) ? dotColor(q) : Color.clear)
                            .frame(width: dotSize, height: dotSize)
                    }
                }.frame(height: 6)
            }
            .frame(width: cellW, height: cellH)
            .background(dayBackground(isSelected: isSelected, isToday: isToday, isHovered: isHovered))
        }
        .buttonStyle(.plain)
        .onHover { hovering in hoveredDate = hovering ? date : nil }
    }

    @ViewBuilder
    private func dayBackground(isSelected: Bool, isToday: Bool, isHovered: Bool) -> some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 5).fill(Color.teal.opacity(0.55))
        } else if isToday {
            RoundedRectangle(cornerRadius: 5).stroke(Color.teal.opacity(0.55), lineWidth: 1)
        } else if isHovered {
            RoundedRectangle(cornerRadius: 5).fill(Color.primary.opacity(0.08))
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────
    private var monthYearString: String {
        let df = DateFormatter(); df.locale = loc.dateLocale
        df.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMMM yyyy", options: 0, locale: loc.dateLocale)
        return df.string(from: displayMonth)
    }
    private var weekdaySymbols: [String] {
        let df = DateFormatter(); df.locale = loc.dateLocale
        var syms = df.veryShortWeekdaySymbols ?? ["S","M","T","W","T","F","S"]
        let firstDay = cal.firstWeekday
        if firstDay > 1 { syms = Array(syms[firstDay-1..<syms.count]) + Array(syms[0..<firstDay-1]) }
        return syms
    }
    private var firstWeekdayOffset: Int {
        guard let start = cal.date(from: cal.dateComponents([.year, .month], from: displayMonth)) else { return 0 }
        var wd = cal.component(.weekday, from: start) - cal.firstWeekday
        if wd < 0 { wd += 7 }
        return wd
    }
    private var daysInMonth: Int { cal.range(of: .day, in: .month, for: displayMonth)?.count ?? 30 }
    private func dateFor(day: Int) -> Date {
        var c = cal.dateComponents([.year, .month], from: displayMonth); c.day = day
        return cal.date(from: c) ?? Date()
    }
    private func changeMonth(_ delta: Int) {
        if let m = cal.date(byAdding: .month, value: delta, to: displayMonth) { displayMonth = m }
    }
    private func dotColor(_ q: TodoItem.Quadrant) -> Color { q.themeColor }
}
