import Foundation
import AppKit
import SwiftUI

struct WidgetTask: Identifiable, Codable {
    var id: String; var name: String; var important: Bool; var urgent: Bool; var completed: Bool
    var priority: Int { switch (important, urgent) { case (true,true):0; case (true,false):1; case (false,true):2; default:3 } }
}
let widgetSuite = UserDefaults(suiteName: "group.com.onedayday.app")

struct SheetConfig: Equatable {
    var date: String?; var quadrant: TodoItem.Quadrant?; var editing: TodoItem?
    var titleOverride: String?
    var templateMode: Bool = false
    var editingTemplateId: String?
    static func == (lhs: SheetConfig, rhs: SheetConfig) -> Bool { lhs.date == rhs.date && lhs.quadrant == rhs.quadrant && lhs.editing?.id == rhs.editing?.id && lhs.titleOverride == rhs.titleOverride && lhs.templateMode == rhs.templateMode && lhs.editingTemplateId == rhs.editingTemplateId }
}

final class TodoViewModel: ObservableObject {
    @Published var todos: [TodoItem] = []
    @Published var triggerAddSheet = false
    @Published var triggerInboxSheet = false
    @Published var showSettings = false
    @Published var sheetConfig: SheetConfig? = nil
    @Published var loadError: Error? = nil
    @Published var hasLoaded = false
    @Published var spotlightTarget: (date: Date, taskId: String)? = nil
    @AppStorage("timelineMigrationDone") private var migrationDone = false
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false

    private let baseURL: URL = {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents/Onedayday_Data")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()
    private var dataURL: URL { baseURL.appendingPathComponent("todos.json") }

    func load() {
        guard !hasLoaded else { return }
        do {
            let data = try Data(contentsOf: dataURL)
            let decoded = try JSONDecoder().decode([TodoItem].self, from: data)
            todos = decoded
        } catch {
            loadError = error
            todos = []
            hasLoaded = true
            return
        }
        migrateTimelineFormat()
        syncWidgetData()
        hasLoaded = true
    }

    func seedPresets(svm: SettingsViewModel, loc: LocalizationManager) {
        guard !hasLaunchedBefore else { return }
        // Clear any test data, start fresh
        todos = []
        let today = Self.dateString(from: Date())
        let welcome = TodoItem(
            name: "preset_welcome_name", device: loc.t("device_computer"),
            date: today, createdDate: today, important: true, urgent: true, completed: false,
            description: "preset_welcome_desc", presetKey: "preset_welcome",
            startHour: 9 * 60, endHour: 10 * 60
        )
        let inbox = TodoItem(
            name: "preset_inbox_name", device: loc.t("device_computer"),
            date: nil, createdDate: today, important: false, urgent: false, completed: false,
            description: "preset_inbox_desc", presetKey: "preset_inbox"
        )
        todos.append(contentsOf: [welcome, inbox])
        save()
        // Reset devices to defaults with localized names
        svm.devices = [
            DeviceConfig(name: loc.t("device_computer"), sfSymbol: "desktopcomputer"),
            DeviceConfig(name: loc.t("device_phone"),    sfSymbol: "iphone"),
            DeviceConfig(name: loc.t("device_tablet"),   sfSymbol: "ipad"),
            DeviceConfig(name: loc.t("device_watch"),    sfSymbol: "applewatch"),
            DeviceConfig(name: loc.t("device_notebook"), sfSymbol: "note.text"),
        ]; svm.saveDevices()
        // Clear templates and add preset
        svm.templates = []
        let tpl = TaskTemplate(name: "preset_template_name", important: true, urgent: false,
                               device: loc.t("device_notebook"), description: "preset_template_desc",
                               estimatedTime: "15m", presetKey: "preset_template")
        svm.addTemplate(tpl)
        hasLaunchedBefore = true
    }

    func resetAllData(svm: SettingsViewModel, loc: LocalizationManager) {
        todos = []
        svm.templates = []
        svm.devices = DeviceConfig.defaults
        svm.saveDevices()
        try? FileManager.default.removeItem(at: baseURL)
        try? FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        UserDefaults.standard.set(false, forKey: "hasLaunchedBefore")
        hasLaunchedBefore = false
        save()
        svm.saveTemplates()
        seedPresets(svm: svm, loc: loc)
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(todos)
            try data.write(to: dataURL, options: .atomic)
        } catch {
            print("Onedayday save error: \(error)")
        }
        syncWidgetData()
        if UserDefaults.standard.bool(forKey: "spotlightIndexEnabled") {
            reindexSpotlight()
        }
    }

    private func migrateTimelineFormat() {
        if migrationDone { return }
        var changed = false
        for i in 0..<todos.count {
            guard i < todos.count else { break }
            if let s = todos[i].startHour, s < 60, let e = todos[i].endHour, e < 120 {
                todos[i].startHour = s * 60; todos[i].endHour = e * 60; changed = true
            }
        }
        migrationDone = true; if changed { save() }
    }

    func add(_ item: TodoItem) { todos.append(item); save() }
    func update(_ item: TodoItem) {
        guard let idx = todos.firstIndex(where: { $0.id == item.id }) else { return }
        todos[idx] = item; save()
    }
    func delete(_ item: TodoItem) { todos.removeAll { $0.id == item.id }; save() }

    func toggleComplete(_ item: TodoItem) {
        guard let idx = todos.firstIndex(where: { $0.id == item.id }) else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { todos[idx].completed.toggle() }
        save()
    }

    func moveItem(id: String, toDate date: String?, toQuadrant: TodoItem.Quadrant? = nil,
                  toImportant: Bool? = nil, toUrgent: Bool? = nil) {
        guard let idx = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[idx].date = date
        if let q = toQuadrant {
            switch q {
            case .importantUrgent:       todos[idx].important = true;  todos[idx].urgent = true
            case .importantNotUrgent:    todos[idx].important = true;  todos[idx].urgent = false
            case .notImportantUrgent:    todos[idx].important = false; todos[idx].urgent = true
            case .notImportantNotUrgent: todos[idx].important = false; todos[idx].urgent = false
            }
        }
        if let imp = toImportant { todos[idx].important = imp }
        if let urg = toUrgent     { todos[idx].urgent = urg }
        save()
    }
    func moveToInbox(id: String) { moveItem(id: id, toDate: nil) }

    // ── Timeline ────────────────────────────────────────────────────────
    func moveToTimeline(id: String, date: String?, startMin: Int, endMin: Int) {
        guard let idx = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[idx].date = date
        todos[idx].startHour = Self.snap5(startMin); todos[idx].endHour = Self.snap5(endMin)
        save()
    }
    func updateTimelineItem(id: String, startMin: Int, endMin: Int) {
        guard let idx = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[idx].startHour = Self.snap5(startMin); todos[idx].endHour = Self.snap5(endMin)
        save()
    }
    func removeFromTimeline(id: String) {
        guard let idx = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[idx].startHour = nil; todos[idx].endHour = nil; save()
    }
    func timelineItems(for date: String) -> [TodoItem] {
        todos.filter { $0.date == date && $0.startHour != nil && !$0.completed }
            .sorted { ($0.startHour ?? 0) < ($1.startHour ?? 0) }
    }

    /// Which quadrants have tasks on a given date (for calendar dots)
    func quadrantPresence(for date: String) -> Set<TodoItem.Quadrant> {
        var set = Set<TodoItem.Quadrant>()
        for item in todos where item.date == date && !item.completed {
            set.insert(item.quadrant)
        }
        return set
    }

    static func snap5(_ minutes: Int) -> Int { max(0, min(1435, Int((Double(minutes)/5.0).rounded()*5))) }
    static func minutesFromDate(_ date: Date) -> Int {
        let cal = Calendar.current; return cal.component(.hour, from: date)*60 + cal.component(.minute, from: date)
    }
    static func dateFromMinutes(_ minutes: Int) -> Date {
        Calendar.current.date(from: DateComponents(hour: minutes/60, minute: minutes%60)) ?? Date()
    }

    var inboxItems: [TodoItem] { todos.filter { $0.date == nil && !$0.completed } }
    func tasks(for quadrant: TodoItem.Quadrant, date: String, showCompleted: Bool) -> [TodoItem] {
        todos.filter { $0.quadrant == quadrant && $0.date == date && (showCompleted || !$0.completed) }
    }
    var todayUrgentTasks: [TodoItem] {
        todos.filter { $0.date == Self.dateString(from: Date()) && $0.urgent && !$0.completed }
    }
    var todayAllTasksSorted: [TodoItem] {
        let today = Self.dateString(from: Date())
        return todos.filter { $0.date == today && !$0.completed }.sorted { $0.prioritySortOrder < $1.prioritySortOrder }
    }
    func activeCount(for date: String) -> Int { todos.filter { !$0.completed && $0.date == date }.count }
    func stats(for date: String) -> (total: Int, completed: Int) {
        let day = todos.filter { $0.date == date }; return (day.count, day.filter(\.completed).count)
    }

    func heatmapData() -> [(date: String, count: Int)] {
        let cal = Calendar.current
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX")
        var counts: [String: Int] = [:]
        for item in todos { guard item.completed, let d = item.date else { continue }; counts[d, default: 0] += 1 }
        var result: [(String, Int)] = []
        for dayOffset in 0..<380 {
            guard let d = cal.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            result.append((f.string(from: d), counts[f.string(from: d)] ?? 0))
        }
        return result.reversed()
    }

    private func reindexSpotlight() { SpotlightIndexer.deindexAll(); for item in todos { SpotlightIndexer.index(item) } }
    func handleSpotlightNavigation(_ identifier: String) {
        let taskId = identifier.replacingOccurrences(of: "com.onedayday.task.", with: "")
        guard let task = todos.first(where: { $0.id == taskId }) else { return }
        if let dateStr = task.date {
            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX")
            if let date = f.date(from: dateStr) { spotlightTarget = (date, taskId) }
        }
        sheetConfig = SheetConfig(editing: task)
    }
    func syncWidgetData() {
        let today = Self.dateString(from: Date())
        let tasks: [WidgetTask] = todos.filter { $0.date == today }
            .sorted { $0.prioritySortOrder < $1.prioritySortOrder }
            .map { WidgetTask(id: $0.id, name: $0.name, important: $0.important, urgent: $0.urgent, completed: $0.completed) }
        guard let enc = try? JSONEncoder().encode(tasks), let ws = widgetSuite else { return }
        ws.set(enc, forKey: "todayWidgetTasks"); ws.synchronize()
    }
    static func dateString(from date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: date)
    }
    static var today: String { dateString(from: Date()) }
}
