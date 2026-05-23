import Foundation

struct DeviceConfig: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var sfSymbol: String
}

extension DeviceConfig {
    static let defaults: [DeviceConfig] = [
        DeviceConfig(name: "Mac",         sfSymbol: "desktopcomputer"),
        DeviceConfig(name: "iPhone",      sfSymbol: "iphone"),
        DeviceConfig(name: "iPad",        sfSymbol: "ipad"),
        DeviceConfig(name: "Apple Watch", sfSymbol: "applewatch"),
        DeviceConfig(name: "Notebook",    sfSymbol: "note.text"),
    ]

    static func sfSymbol(for name: String, in devices: [DeviceConfig]) -> String {
        devices.first(where: { $0.name == name })?.sfSymbol ?? "questionmark"
    }
}

import SwiftUI

extension Color {
    /// Semantic card/panel background that adapts to light & dark modes.
    static var backgroundCard: Color { Color(nsColor: .windowBackgroundColor).opacity(0.92) }
}
