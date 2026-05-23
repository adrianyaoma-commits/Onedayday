import SwiftUI

struct HeaderView: View {
    @EnvironmentObject var loc: LocalizationManager
    @Binding var selectedDate: Date
    @Binding var showCalendar: Bool
    let total: Int
    let completed: Int

    private var dateLabel: String {
        let cal = Calendar.current
        let iso = DateFormatter(); iso.dateFormat = "yyyy-MM-dd"; iso.locale = Locale(identifier: "en_US_POSIX")
        let today = iso.string(from: Date())
        let selected = iso.string(from: selectedDate)

        if selected == today {
            return loc.t("dynamic_today")
        }
        if let tomorrow = cal.date(byAdding: .day, value: 1, to: Date()),
           iso.string(from: tomorrow) == selected {
            return loc.t("dynamic_tomorrow")
        }

        // Locale-aware formatting for all other dates
        let df = DateFormatter()
        df.locale = loc.dateLocale
        df.dateFormat = DateFormatter.dateFormat(
            fromTemplate: "MMMdd EEEE",
            options: 0,
            locale: loc.dateLocale
        )
        return df.string(from: selectedDate)
    }

    private var progress: Double {
        total == 0 ? 0 : Double(completed) / Double(total)
    }

    var body: some View {
        Button(action: { withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            showCalendar.toggle()
        }}) {
            HStack(spacing: 10) {
                Text(dateLabel)
                    .font(.system(size: 24, weight: .bold, design: .default))
                    .foregroundStyle(.primary)

                ZStack {
                    Circle()
                        .stroke(.quaternary, lineWidth: 3)
                        .frame(width: 30, height: 30)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            progress >= 1.0 ? Color.green : Color.blue,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 30, height: 30)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.8), value: progress)
                    Text("\(completed)/\(total)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded)).monospacedDigit()
                        .foregroundStyle(.secondary)
                }

                Image(systemName: showCalendar ? "sidebar.right" : "sidebar.left")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(showCalendar ? .blue : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
