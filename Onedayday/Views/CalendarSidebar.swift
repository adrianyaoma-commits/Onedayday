import SwiftUI

struct CalendarSidebar: View {
    @EnvironmentObject var loc: LocalizationManager
    @Binding var selectedDate: Date
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(loc.t("calendar_title"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                        isExpanded = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.top, 6)

            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(.teal)
                .colorMultiply(Color(nsColor: .controlBackgroundColor).opacity(0.02))
                .padding(.horizontal, 4)
                .clipped()

            Button(action: { selectedDate = Date() }) {
                Label(loc.t("jump_today"), systemImage: "arrow.uturn.backward")
                    .font(.system(size: 10, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.teal)
            .padding(.bottom, 8)

            Divider().opacity(0.3)
            Spacer()
        }
        .frame(width: 220)
        .background(.ultraThinMaterial)
    }
}
