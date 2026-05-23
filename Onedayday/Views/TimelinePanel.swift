import SwiftUI

struct TimelinePanel: View {
    @EnvironmentObject var vm: TodoViewModel
    @EnvironmentObject var loc: LocalizationManager
    let date: String

    @State private var now: Date = Date()
    private let timer = Timer.publish(every: 120, on: .main, in: .common).autoconnect()

    private var currentMinutes: CGFloat {
        let cal = Calendar.current
        return CGFloat(cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now))
    }
    private let hourHeight: CGFloat = 52
    private var minuteHeight: CGFloat { hourHeight / 60.0 }
    private let topPadding: CGFloat = 4
    private var totalHeight: CGFloat { hourHeight * 24 + topPadding + 8 }

    private var isShowingToday: Bool {
        TodoViewModel.dateString(from: Date()) == date
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label(loc.t("timeline_title"), systemImage: "clock")
                    .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                Spacer()
            }.padding(.horizontal, 10).padding(.vertical, 6)
            Divider().opacity(0.3)

            ScrollViewReader { proxy in
                ScrollView {
                    ZStack(alignment: .topLeading) {
                        VStack(spacing: 0) {
                            ForEach(0..<24, id: \.self) { hour in
                                VStack(spacing: 0) {
                                    HStack(spacing: 0) {
                                        Text(String(format: "%02d:00", hour))
                                            .font(.system(size: 11, design: .rounded)).monospacedDigit()
                                            .foregroundStyle(.tertiary).frame(width: 36, alignment: .trailing)
                                        Rectangle().fill(.quaternary).frame(height: 0.5)
                                    }.frame(height: hourHeight, alignment: .top)
                                }
                            }
                        }.padding(.top, topPadding)

                        ForEach(vm.timelineItems(for: date), id: \.self) { item in
                            TimeBlockView(item: item, hourHeight: hourHeight)
                        }

                        if isShowingToday {
                            Rectangle().fill(.red).frame(height: 1.5)
                                .padding(.top, currentMinutes * minuteHeight + topPadding)
                        }
                    }
                    .coordinateSpace(name: "TimelineSpace")
                    .frame(minHeight: totalHeight)
                }
                .scrollIndicators(.hidden)
                .onDrop(of: [.plainText], isTargeted: nil) { providers, location in
                    handleDrop(providers: providers, contentY: location.y)
                }
                .onAppear { proxy.scrollTo(Int(currentMinutes / 60), anchor: .center) }
                .onReceive(timer) { _ in now = Date() }
            }
        }
        .frame(maxWidth: .infinity).background(.ultraThinMaterial)
    }

    private func handleDrop(providers: [NSItemProvider], contentY: CGFloat) -> Bool {
        let yInContent = contentY - topPadding
        let rawMin = yInContent / hourHeight * 60.0
        let snapped = TodoViewModel.snap5(Int(rawMin))
        let clamped = max(0, min(1435, snapped))
        let end = TodoViewModel.snap5(clamped + 60)
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.plain-text", options: nil) { data, _ in
                if let data = data as? Data, let id = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        vm.moveToTimeline(id: id, date: date, startMin: clamped, endMin: end)
                    }
                }
            }
        }
        return true
    }
}
