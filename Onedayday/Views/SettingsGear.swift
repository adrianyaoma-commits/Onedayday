import SwiftUI

struct SettingsGear: View {
    @EnvironmentObject var vm: TodoViewModel
    @EnvironmentObject var loc: LocalizationManager

    var body: some View {
        Button { vm.showSettings = true } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .buttonStyle(.plain)
        .help(loc.t("settings_gear"))
    }
}
