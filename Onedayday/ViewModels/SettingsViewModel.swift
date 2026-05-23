import Foundation
import SwiftUI

final class SettingsViewModel: ObservableObject {
    @Published var devices: [DeviceConfig] = []
    @Published var templates: [TaskTemplate] = []

    private let baseURL: URL = {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents/Onedayday_Data")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private var devicesURL: URL { baseURL.appendingPathComponent("devices.json") }
    private var templatesURL: URL { baseURL.appendingPathComponent("templates.json") }

    init() {
        loadDevices()
        loadTemplates()
        if devices.isEmpty { devices = DeviceConfig.defaults; saveDevices() }
    }

    // ── Devices ─────────────────────────────────────────────────────
    func loadDevices() {
        guard let d = try? Data(contentsOf: devicesURL),
              let list = try? JSONDecoder().decode([DeviceConfig].self, from: d)
        else { devices = []; return }
        devices = list
    }

    func saveDevices() {
        guard let d = try? JSONEncoder().encode(devices) else { return }
        try? d.write(to: devicesURL, options: .atomic)
    }

    func addDevice(_ name: String, sfSymbol: String) {
        devices.append(DeviceConfig(name: name, sfSymbol: sfSymbol))
        saveDevices()
    }

    func updateDevice(_ item: DeviceConfig) {
        guard let idx = devices.firstIndex(where: { $0.id == item.id }) else { return }
        devices[idx] = item
        saveDevices()
    }

    func deleteDevice(_ item: DeviceConfig) {
        devices.removeAll { $0.id == item.id }
        saveDevices()
    }

    func sfSymbol(for name: String) -> String {
        DeviceConfig.sfSymbol(for: name, in: devices)
    }

    // ── Templates ───────────────────────────────────────────────────
    func loadTemplates() {
        guard let d = try? Data(contentsOf: templatesURL),
              let list = try? JSONDecoder().decode([TaskTemplate].self, from: d)
        else { templates = []; return }
        templates = list
    }

    func saveTemplates() {
        guard let d = try? JSONEncoder().encode(templates) else { return }
        try? d.write(to: templatesURL, options: .atomic)
    }

    func addTemplate(_ t: TaskTemplate) {
        templates.append(t)
        saveTemplates()
    }

    func updateTemplate(_ t: TaskTemplate) {
        guard let idx = templates.firstIndex(where: { $0.id == t.id }) else { return }
        templates[idx] = t
        saveTemplates()
    }

    func deleteTemplate(_ t: TaskTemplate) {
        templates.removeAll { $0.id == t.id }
        saveTemplates()
    }
}
