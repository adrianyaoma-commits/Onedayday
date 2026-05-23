import Foundation

struct TodoItem: Identifiable, Codable, Equatable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var filePath: String?
    var device: String = "Mac"
    var date: String?       // nil = Inbox item
    var createdDate: String
    var clonedFrom: String?
    var important: Bool
    var urgent: Bool
    var completed: Bool
    var description: String?
    var deliverable: String?
    var estimatedTime: String?
    var presetKey: String? = nil
    // ── v5.2 timeline fields (minutes from midnight, 0-1439, 5-min snap) ──
    var startHour: Int?     // nil = not on timeline; value = minutes 0–1439
    var endHour: Int?

    var isInInbox: Bool { date == nil && startHour == nil }
    var isOnTimeline: Bool { startHour != nil }

    var timelineDuration: Int {
        guard let s = startHour, let e = endHour, e > s else { return 60 }
        return e - s
    }
    var displayStart: String {
        guard let s = startHour else { return "" }
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
    var displayEnd: String {
        guard let e = endHour else { return "" }
        return String(format: "%02d:%02d", e / 60, e % 60)
    }
    var durationDisplay: String {
        guard let s = startHour, let e = endHour, e > s else { return "" }
        let diff = e - s
        let h = diff / 60
        let m = diff % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}

import SwiftUI

extension TodoItem.Quadrant {
    var themeColor: Color {
        switch self {
        case .importantUrgent:       return .red
        case .importantNotUrgent:    return .orange
        case .notImportantUrgent:    return .yellow
        case .notImportantNotUrgent: return .mint
        }
    }
    static func from(important: Bool, urgent: Bool) -> TodoItem.Quadrant {
        switch (important, urgent) {
        case (true, true):   return .importantUrgent
        case (true, false):  return .importantNotUrgent
        case (false, true):  return .notImportantUrgent
        case (false, false): return .notImportantNotUrgent
        }
    }
}

extension TodoItem {
    enum Quadrant: String, CaseIterable {
        case importantUrgent        = "importantUrgent"
        case importantNotUrgent     = "importantNotUrgent"
        case notImportantUrgent     = "notImportantUrgent"
        case notImportantNotUrgent  = "notImportantNotUrgent"
    }

    var quadrant: Quadrant {
        switch (important, urgent) {
        case (true,  true):  return .importantUrgent
        case (true,  false): return .importantNotUrgent
        case (false, true):  return .notImportantUrgent
        case (false, false): return .notImportantNotUrgent
        }
    }

    var prioritySortOrder: Int {
        switch (important, urgent) {
        case (true,  true):  return 0
        case (true,  false): return 1
        case (false, true):  return 2
        case (false, false): return 3
        }
    }

    func visualDateLabel() -> String? {
        guard let d = date else { return nil }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        guard let dateObj = f.date(from: d) else { return d }
        let cal = Calendar.current
        if cal.isDateInToday(dateObj)     { return "__today__" }
        if cal.isDateInTomorrow(dateObj)  { return "__tomorrow__" }
        let df = DateFormatter()
        df.dateFormat = "EEE, MMM d"
        df.locale = Locale.current
        return df.string(from: dateObj)
    }
}
