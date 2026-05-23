import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject var vm: TodoViewModel
    @EnvironmentObject var loc: LocalizationManager
    @EnvironmentObject var svm: SettingsViewModel
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"
    @State private var showCompleted = false
    @State private var showHeatmap = false
    @State private var selectedDate: Date = Date()
    @State private var showSidebar = true
    @State private var showTimeline = false
    private var dateString: String { TodoViewModel.dateString(from: selectedDate) }
    private var stats: (total: Int, completed: Int) { vm.stats(for: dateString) }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Top bar
                HStack(spacing: 0) {
                    HeaderView(selectedDate: $selectedDate, showCalendar: $showSidebar,
                               total: stats.total, completed: stats.completed).padding(.leading, 16)
                    Spacer()
                    QuickAddButton { vm.sheetConfig = SheetConfig(date: dateString) }
                    ToolbarIconButton(icon: "calendar.day.timeline.left", activeColor: .blue, isActive: showTimeline) {
                        withAnimation(.easeInOut(duration: 0.25)) { showTimeline.toggle() }
                    }
                    ToolbarIconButton(icon: "chart.bar.fill", activeColor: .secondary) {
                        showHeatmap = true
                    }
                    Toggle(isOn: $showCompleted) {
                        Text(loc.t("show_completed")).font(.system(size: 11)).foregroundStyle(.secondary)
                    }.toggleStyle(.checkbox).controlSize(.small).padding(.trailing, 16)
                    SettingsGear().padding(.trailing, 14)
                }.frame(height: 50).background(.ultraThinMaterial)
                Divider().opacity(0.4)

                // Body
                HStack(spacing: 0) {
                    if showSidebar {
                        unifiedSidebar.frame(width: 230)
                            .frame(maxHeight: .infinity)
                        panelDivider
                    }
                    Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                        GridRow {
                            QuadrantPanel(quadrant: .importantUrgent, date: dateString, showCompleted: showCompleted)
                            QuadrantPanel(quadrant: .importantNotUrgent, date: dateString, showCompleted: showCompleted)
                        }
                        GridRow {
                            QuadrantPanel(quadrant: .notImportantUrgent, date: dateString, showCompleted: showCompleted)
                            QuadrantPanel(quadrant: .notImportantNotUrgent, date: dateString, showCompleted: showCompleted)
                        }
                    }.padding(8).layoutPriority(1)
                    .frame(maxHeight: .infinity)
                    .padding(.bottom, 16)
                    if showTimeline {
                        panelDivider
                        TimelinePanel(date: dateString).frame(width: 315)
                    }
                }
                // Status
                HStack {
                    Text("\(loc.t("active_count_label")): \(stats.total)")
                        .font(.system(size: 11, design: .monospaced)).foregroundStyle(.tertiary).padding(.leading, 16)
                    Spacer()
                }.frame(height: 24).background(.ultraThinMaterial)
            }
            .background(.ultraThinMaterial).id(loc.language)

            // ── Unified overlay: Heatmap ──
            if showHeatmap {
                Color.black.opacity(0.35).ignoresSafeArea()
                    .onTapGesture { showHeatmap = false }
                HeatmapView()
            }

            // ── Unified overlay: Settings ──
            if vm.showSettings {
                Color.black.opacity(0.35).ignoresSafeArea()
                    .onTapGesture { vm.showSettings = false }
                SettingsView()
            }

            // ── Unified overlay: AddTaskSheet (above Settings) ──
            if let config = vm.sheetConfig {
                Color.black.opacity(0.35).ignoresSafeArea()
                    .onTapGesture { vm.sheetConfig = nil }
                AddTaskSheet(quadrant: config.quadrant, date: config.date, editing: config.editing, titleOverride: config.titleOverride, templateMode: config.templateMode, editingTemplateId: config.editingTemplateId)
            }
        }
        .alert(loc.t("load_error_title"), isPresented: Binding(get: { vm.loadError != nil }, set: { if !$0 { vm.loadError = nil } })) {
            Button(loc.t("ok")) { vm.loadError = nil }
        } message: {
            Text(loc.t("load_error_msg"))
        }
        .animation(.easeInOut(duration: 0.2), value: vm.sheetConfig != nil)
        .animation(.easeInOut(duration: 0.2), value: showHeatmap)
        .animation(.easeInOut(duration: 0.2), value: vm.showSettings)
        .preferredColorScheme(appearanceMode == "light" ? .light : (appearanceMode == "dark" ? .dark : nil))
        .onReceive(vm.$triggerAddSheet) { if $0 { vm.sheetConfig = SheetConfig(date: dateString); vm.triggerAddSheet = false } }
        .onReceive(vm.$triggerInboxSheet) { if $0 { vm.sheetConfig = SheetConfig(date: nil); vm.triggerInboxSheet = false } }
        .onReceive(vm.$spotlightTarget) { target in
            if let (date, _) = target { selectedDate = date }
        }
    }

    private var panelDivider: some View {
        Rectangle().fill(.quaternary).frame(width: 3)
    }

    private var unifiedSidebar: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                CustomCalendarView(selectedDate: $selectedDate).padding(.horizontal, 6).padding(.top, 4)
                Button(action: { selectedDate = Date() }) {
                    Label(loc.t("jump_today"), systemImage: "arrow.uturn.backward")
                        .font(.system(size: 10, weight: .medium))
                }.buttonStyle(.plain).foregroundStyle(.teal.opacity(0.7)).padding(.vertical, 3)
            }
            HStack(spacing: 0) {}.frame(height: 2)
            Rectangle().fill(.quaternary).frame(height: 0.5).padding(.horizontal, 8)
            VStack(spacing: 0) {
                HStack {
                    Label(loc.t("inbox_title"), systemImage: "tray")
                        .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                    Spacer()
                    Text("\(vm.inboxItems.count)").font(.system(size: 10, design: .monospaced)).foregroundStyle(.tertiary)
                    Button { vm.sheetConfig = SheetConfig(date: nil) } label: {
                        Image(systemName: "plus.circle.fill").font(.system(size: 14)).foregroundStyle(.blue)
                    }.buttonStyle(.plain)
                }.padding(.horizontal, 10).padding(.vertical, 6)
                let items = vm.inboxItems
                if items.isEmpty {
                    Text(loc.t("empty_inbox")).font(.system(size: 11)).foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center).frame(maxWidth: .infinity).padding(.top, 16)
                    Spacer(minLength: 0)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 3) {
                            ForEach(items) { item in
                                InboxRowView(item: item).onDrag { NSItemProvider(object: item.id as NSString) }
                            }
                        }.padding(.horizontal, 6).padding(.vertical, 4)
                    }.scrollIndicators(.hidden)
                }
            }
            .onDrop(of: [.plainText], isTargeted: nil) { providers in
                for provider in providers {
                    provider.loadItem(forTypeIdentifier: "public.plain-text", options: nil) { data, _ in
                        if let data = data as? Data, let id = String(data: data, encoding: .utf8) {
                            DispatchQueue.main.async { vm.moveToInbox(id: id) }
                        }
                    }
                }
                return true
            }

            Spacer(minLength: 0)

            // ── Pomodoro timer ──
            Rectangle().fill(.quaternary).frame(height: 0.5).padding(.horizontal, 8)
            SidebarPomodoroView()
                .padding(.bottom, 0)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(.ultraThinMaterial)
    }
}

// MARK: - Sidebar Pomodoro Timer
struct SidebarPomodoroView: View {
    @EnvironmentObject var loc: LocalizationManager
    @State private var totalSeconds: Int = 25 * 60
    @State private var remaining: Int = 25 * 60
    @State private var isRunning: Bool = false
    @State private var cancellable: AnyCancellable? = nil
    @State private var showStartMsg: Bool = false
    @State private var showDoneMsg: Bool = false

    private let presets: [(String, Int)] = [
        ("15m", 15), ("25m", 25), ("45m", 45), ("60m", 60)
    ]

    var body: some View {
        VStack(spacing: 4) {
            // Row 1: Title + Reset
            HStack {
                Label(loc.t("pomodoro_title"), systemImage: "timer")
                    .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                Spacer()
                if !isRunning, remaining != totalSeconds {
                    Button(action: { remaining = totalSeconds; showStartMsg = false; showDoneMsg = false }) {
                        Text(loc.t("pomodoro_reset")).font(.system(size: 10)).foregroundStyle(.secondary)
                    }.buttonStyle(.plain)
                }
            }
            .frame(height: 20)
            .padding(.horizontal, 10)

            // Countdown — large, bold, airy
            Text(formatTime(remaining))
                .font(.system(size: 30, weight: .bold, design: .rounded)).monospacedDigit()
                .foregroundStyle(isRunning ? .secondary : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)

            // Preset buttons
            HStack(spacing: 4) {
                ForEach(presets, id: \.0) { label, min in
                    Button(action: { if !isRunning { totalSeconds = min * 60; remaining = totalSeconds } }) {
                        Text(label)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(totalSeconds == min * 60 ? .white : .secondary)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(
                                totalSeconds == min * 60 ? Color.red.opacity(0.6) : Color.primary.opacity(0.08),
                                in: Capsule()
                            )
                    }.buttonStyle(.plain)
                    .disabled(isRunning)
                }
            }
            .padding(.horizontal, 10)
            .opacity(isRunning ? 0.35 : 1)

            // Start/Pause button
            Button(action: toggleTimer) {
                Label(
                    isRunning ? loc.t("pomodoro_pause") : (showStartMsg ? loc.t("pomodoro_ready") : loc.t("pomodoro_start")),
                    systemImage: isRunning ? "pause.fill" : "play.fill"
                )
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isRunning ? .orange : .green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 10)
            .padding(.top, 20)

            // Done message
            Text(showDoneMsg ? loc.t("pomodoro_done") : " ")
                .font(.system(size: 10)).foregroundStyle(.teal)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                .frame(height: 16)
        }
        .padding(.vertical, 8)
    }

    private func toggleTimer() {
        if isRunning { stopTimer() }
        else { showStartMsg = true; showDoneMsg = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showStartMsg = false; startTimer()
            }
        }
    }

    private func startTimer() {
        isRunning = true
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if remaining > 0 { remaining -= 1 }
                else { stopTimer(); showDoneMsg = true }
            }
    }

    private func stopTimer() {
        isRunning = false
        cancellable?.cancel()
        cancellable = nil
    }

    private func formatTime(_ sec: Int) -> String {
        String(format: "%02d:%02d", sec / 60, sec % 60)
    }
}

struct InboxRowView: View {
    @EnvironmentObject var vm: TodoViewModel
    @EnvironmentObject var loc: LocalizationManager
    @EnvironmentObject var svm: SettingsViewModel
    let item: TodoItem
    @State private var isHovered = false; @State private var isExpanded = false
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Button {
                    vm.toggleComplete(item)
                    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
                } label: {
                    Image(systemName: item.completed ? "checkmark.circle.fill" : "circle").font(.system(size: 12))
                        .foregroundStyle(item.completed ? Color.green : Color.gray).contentTransition(.symbolEffect(.replace))
                }.buttonStyle(.plain).fixedSize()
                Text(loc.presetName(for: item)).font(.system(size: 11)).lineLimit(1).truncationMode(.tail)
                    .foregroundStyle(item.completed ? .secondary : .primary).strikethrough(item.completed)
                    .frame(maxWidth: .infinity, alignment: .leading)
                let dur = item.durationDisplay
                if !dur.isEmpty {
                    Text(dur).font(.system(size: 11, design: .rounded)).monospacedDigit().foregroundStyle(.tertiary)
                        .padding(.horizontal, 4).padding(.vertical, 1).background(.quaternary, in: RoundedRectangle(cornerRadius: 2))
                        .fixedSize()
                }
                if isHovered {
                    ActionButtonsView(
                        onEdit: { vm.sheetConfig = SheetConfig(editing: item) },
                        onDelete: { vm.delete(item) }
                    )
                }
            }.padding(.horizontal, 10).padding(.vertical, 4).contentShape(Rectangle())
            .onHover { hovering in withAnimation(.easeInOut(duration: 0.15)) { isHovered = hovering } }
            .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    if let desc = loc.presetDesc(for: item), !desc.isEmpty {
                        Text(desc).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(3)
                            .padding(.leading, 18)
                    }
                    let deviceNames = item.device.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                    if !deviceNames.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(deviceNames, id: \.self) { d in
                                Label(loc.localizedDeviceName(d), systemImage: svm.sfSymbol(for: d))
                                    .font(.system(size: 11)).foregroundStyle(.tertiary).labelStyle(.titleAndIcon)
                                    .lineLimit(1).fixedSize(horizontal: true, vertical: false)
                            }
                        }.padding(.leading, 18)
                    }
                    if let fp = item.filePath, !fp.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.fill").font(.system(size: 10)).foregroundStyle(.tertiary)
                            Text(URL(fileURLWithPath: fp).lastPathComponent)
                                .font(.system(size: 11)).foregroundStyle(.tertiary).lineLimit(2).truncationMode(.middle)
                        }.padding(.leading, 18)
                    }
                }.padding(.horizontal, 12).padding(.bottom, 6).frame(maxWidth: .infinity, alignment: .leading).transition(.opacity)
            }
        }
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(isHovered ? 0.05 : 0.02)))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5))
    }
}

struct QuickAddButton: View {
    @EnvironmentObject var loc: LocalizationManager
    var action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Label(loc.t("quick_add"), systemImage: "plus.circle.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(hovered ? .white : .blue)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(hovered ? Color.blue : Color.blue.opacity(0.1)))
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onHover { h in withAnimation(.easeInOut(duration: 0.15)) { hovered = h } }
        .padding(.trailing, 6)
    }
}

struct ToolbarIconButton: View {
    let icon: String
    var activeColor: Color = .blue
    var isActive: Bool = true
    var action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(isActive ? (hovered ? .primary : activeColor) : .gray)
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(hovered ? Color.primary.opacity(0.1) : Color.clear)
                )
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onHover { h in withAnimation(.easeInOut(duration: 0.15)) { hovered = h } }
        .padding(.trailing, 6)
    }
}
