import SwiftUI
import CoreSpotlight

@main
struct OnedaydayApp: App {
    @StateObject private var vm = TodoViewModel()
    @StateObject private var loc = LocalizationManager()
    @StateObject private var svm = SettingsViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
                .environmentObject(loc)
                .environmentObject(svm)
                .task { vm.load(); vm.seedPresets(svm: svm, loc: loc) }
                .onContinueUserActivity(CSSearchableItemActionType) { activity in
                    if let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
                        vm.handleSpotlightNavigation(identifier)
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }
        }
        .windowResizability(.contentMinSize)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(before: .newItem) {
                Button(loc.t("shortcut_new")) {
                    vm.triggerAddSheet = true
                }
                .keyboardShortcut("n", modifiers: .command)
                Button(loc.t("shortcut_inbox")) {
                    vm.triggerInboxSheet = true
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }

        MenuBarExtra(loc.t("app_title"), systemImage: "list.bullet.rectangle") {
            MenuBarView()
                .environmentObject(vm)
                .environmentObject(loc)
                .environmentObject(svm)
                .task { vm.load(); vm.seedPresets(svm: svm, loc: loc) }
        }
        .menuBarExtraStyle(.window)

    }
}
