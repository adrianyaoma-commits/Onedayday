import SwiftUI
import AppKit

// MARK: - Shared design tokens
private let rowH: CGFloat = 30
private let rowFont: Font = .system(size: 12)
private let cr: CGFloat = 6
private let dividerOpacity: CGFloat = 0.2

// MARK: - Root settings container
struct SettingsView: View {
    @EnvironmentObject var loc: LocalizationManager
    @EnvironmentObject var svm: SettingsViewModel
    @EnvironmentObject var vm: TodoViewModel
    @State private var selectedTab = 0

    private let tabs: [(icon: String, key: String)] = [
        ("globe", "tab_general"),
        ("command", "tab_shortcuts"),
        ("square.grid.2x2", "template_section"),
        ("desktopcomputer", "tab_devices")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // ── Icon tab bar (large hit area) ──
            HStack(spacing: 0) {
                ForEach(tabs.indices, id: \.self) { idx in
                    let tab = tabs[idx]
                    let sel = selectedTab == idx
                    Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedTab = idx } }) {
                        VStack(spacing: 5) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: .regular))
                                .symbolRenderingMode(.hierarchical)
                                .frame(height: 24)
                            Text(loc.t(tab.key))
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(sel ? Color.primary : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(sel ? Color.primary.opacity(0.08) : Color.clear)
                        )
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 6)

            // ── Unified divider ──
            Rectangle().fill(Color.primary.opacity(dividerOpacity)).frame(height: 1)
                .padding(.horizontal, 4)

            // ── Content ──
            Group {
                switch selectedTab {
                case 0: GeneralSettingsTab().environmentObject(loc).environmentObject(vm).environmentObject(svm)
                case 1: ShortcutsSettingsTab().environmentObject(loc)
                case 2: TemplateSettingsTab().environmentObject(loc).environmentObject(svm).environmentObject(vm)
                case 3: DeviceSettingsTab().environmentObject(loc).environmentObject(svm)
                default: EmptyView()
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 24).padding(.vertical, 20)
        .frame(width: 500, height: 420)
        .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Tab 1: General
struct GeneralSettingsTab: View {
    @EnvironmentObject var loc: LocalizationManager
    @EnvironmentObject var vm: TodoViewModel
    @EnvironmentObject var svm: SettingsViewModel
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"
    @AppStorage("spotlightIndexEnabled") private var spotlightEnabled: Bool = true
    @State private var showPrivacySheet = false
    @State private var showResetConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            settingRow(label: loc.t("language_label")) {
                Picker("", selection: Binding(get: { loc.language }, set: { loc.setLanguage($0) })) {
                    Text(loc.t("lang_zh")).tag("zh"); Text(loc.t("lang_en")).tag("en")
                    Text(loc.t("lang_fr")).tag("fr"); Text(loc.t("lang_ja")).tag("ja")
                }.pickerStyle(.segmented).labelsHidden().frame(maxWidth: 200, alignment: .leading)
            }
            Divider().opacity(dividerOpacity).padding(.horizontal, 16)
            settingRow(label: loc.t("appearance_label")) {
                Picker("", selection: $appearanceMode) {
                    Text(loc.t("appearance_system")).tag("system")
                    Text(loc.t("appearance_light")).tag("light")
                    Text(loc.t("appearance_dark")).tag("dark")
                }.pickerStyle(.segmented).labelsHidden().frame(maxWidth: 200, alignment: .leading)
            }
            Divider().opacity(dividerOpacity).padding(.horizontal, 16)
            settingRow(label: loc.t("privacy_policy")) {
                Button(action: { showPrivacySheet = true }) {
                    Text(loc.t("privacy_button"))
                        .font(.system(size: 12)).foregroundColor(.accentColor)
                }.buttonStyle(.plain)
            }
            Divider().opacity(dividerOpacity).padding(.horizontal, 16)
            settingRow(label: "") {
                Toggle(loc.t("spotlight_toggle"), isOn: $spotlightEnabled)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 12))
            }
            Divider().opacity(dividerOpacity).padding(.vertical, 10)

            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label(loc.t("reset_data"), systemImage: "trash.fill")
                    .font(.system(size: 12))
            }

            Spacer()
            Text(loc.t("version_tagline"))
                .font(.system(size: 10)).foregroundStyle(.tertiary)
                .padding(.bottom, 8)
        }.padding(.horizontal, 16).padding(.top, 12)
        .sheet(isPresented: $showPrivacySheet) {
            VStack(alignment: .leading, spacing: 16) {
                Text(loc.t("privacy_policy"))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                ScrollView {
                    Text(loc.t("privacy_content"))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                HStack {
                    Spacer()
                    Button(loc.t("cancel")) { showPrivacySheet = false }
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
            .frame(width: 400, height: 300)
        }
        .confirmationDialog(loc.t("reset_confirm_title"), isPresented: $showResetConfirm) {
            Button(loc.t("reset_confirm_btn"), role: .destructive) {
                vm.resetAllData(svm: svm, loc: loc)
            }
            Button(loc.t("cancel"), role: .cancel) {}
        } message: {
            Text(loc.t("reset_confirm_msg"))
        }
    }

    private func settingRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 20) {
            Text(label).font(rowFont).foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)
            content()
            Spacer()
        }
        .frame(height: rowH)
        .contentShape(.rect)
    }
}

// MARK: - Tab 2: Shortcuts (NSEvent capture)
struct ShortcutsSettingsTab: View {
    @EnvironmentObject var loc: LocalizationManager
    @AppStorage("shortcutNewTask") private var newTaskKey: String = "Cmd + N"
    @AppStorage("shortcutSettings") private var settingsKey: String = "Cmd + ,"
    @AppStorage("shortcutInbox") private var inboxKey: String = "Cmd + Shift + N"
    @State private var editingField: String? = nil
    @State private var hoveredField: String? = nil
    @State private var keyMonitor: Any?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            shortcutRow(label: loc.t("shortcut_new"), value: $newTaskKey, field: "new")
            Divider().opacity(dividerOpacity).padding(.horizontal, 16)
            shortcutRow(label: loc.t("shortcut_inbox"), value: $inboxKey, field: "inbox")
            Divider().opacity(dividerOpacity).padding(.horizontal, 16)
            shortcutRow(label: loc.t("shortcut_settings"), value: $settingsKey, field: "settings")
            Divider().opacity(dividerOpacity).padding(.horizontal, 16)
            Spacer()
        }.padding(.horizontal, 16).padding(.top, 12)
    }

    private func shortcutRow(label: String, value: Binding<String>, field: String) -> some View {
        let isEditing = editingField == field
        return VStack(spacing: 0) {
            HStack {
                Text(label).font(rowFont)
                    .frame(width: 120, alignment: .leading)
                Spacer()
                Text(value.wrappedValue)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(isEditing ? .primary : .secondary)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(
                        isEditing ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 4)
                    )
                if hoveredField == field, !isEditing {
                    Button(action: { editingField = field }) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 13))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                            .frame(width: 24, height: 24)
                            .contentShape(.rect)
                    }.buttonStyle(.plain)
                }
            }
            .frame(height: rowH)
            .padding(.horizontal, 8)
            .contentShape(.rect)
            .background(
                RoundedRectangle(cornerRadius: cr)
                    .fill(isEditing ? Color.accentColor.opacity(0.06) : (hoveredField == field ? Color.primary.opacity(0.06) : Color.clear))
            )
            .onHover { hovering in withAnimation(.easeInOut(duration: 0.15)) { hoveredField = hovering ? field : nil } }

            if isEditing {
                HStack(spacing: 6) {
                    Image(systemName: "keyboard").font(.system(size: 11)).foregroundStyle(.secondary)
                    Text("\(label) — \(loc.t("shortcut_prompt"))")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                    Spacer()
                    Button(loc.t("cancel")) { editingField = nil; removeKeyMonitor() }
                        .buttonStyle(.plain).font(.system(size: 11))
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.accentColor.opacity(0.04), in: RoundedRectangle(cornerRadius: cr))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .onAppear { installKeyMonitor(field: field, value: value) }
                .onDisappear { removeKeyMonitor() }
            }
        }
    }

    private func installKeyMonitor(field: String, value: Binding<String>) {
        removeKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            var parts: [String] = []
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags.contains(.command) { parts.append("Cmd") }
            if flags.contains(.option)  { parts.append("Opt") }
            if flags.contains(.control) { parts.append("Ctrl") }
            if flags.contains(.shift)   { parts.append("Shift") }
            if let chars = event.charactersIgnoringModifiers, !chars.isEmpty {
                let key = chars.uppercased()
                if key != "CMD" && key != "OPT" && key != "CTRL" && key != "SHIFT" {
                    parts.append(key)
                }
            }
            if !parts.isEmpty {
                value.wrappedValue = parts.joined(separator: " + ")
                DispatchQueue.main.async { editingField = nil }
            }
            return nil
        }
    }

    private func removeKeyMonitor() {
        if let monitor = keyMonitor { NSEvent.removeMonitor(monitor); keyMonitor = nil }
    }
}

// MARK: - Tab 3: Templates
struct TemplateSettingsTab: View {
    @EnvironmentObject var loc: LocalizationManager
    @EnvironmentObject var svm: SettingsViewModel
    @EnvironmentObject var vm: TodoViewModel
    @State private var hoveredId: String?
    @State private var addBtnHovered: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Button(action: { vm.sheetConfig = SheetConfig(date: nil, titleOverride: loc.t("template_new_title"), templateMode: true) }) {
                    Label(loc.t("add_template"), systemImage: "plus.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(addBtnHovered ? .primary : .secondary)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Capsule().fill(addBtnHovered ? Color.primary.opacity(0.12) : Color.primary.opacity(0.06)))
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .onHover { h in withAnimation(.easeInOut(duration: 0.15)) { addBtnHovered = h } }
            }
            .frame(height: 30)
            .padding(.top, 6)
            .padding(.trailing, 16)

            Divider().opacity(dividerOpacity).padding(.horizontal, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                ForEach(svm.templates) { tpl in
                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(TodoItem.Quadrant.from(important: tpl.important, urgent: tpl.urgent).themeColor)
                            .frame(width: 3).padding(.vertical, 8)
                        VStack(alignment: .leading, spacing: 4) {
                            // Row 1: name + duration (estimatedTime)
                            HStack(alignment: .top, spacing: 6) {
                                Text(loc.templateName(for: tpl)).font(.system(size: 14, weight: .semibold, design: .default))
                                    .lineLimit(3).frame(maxWidth: .infinity, alignment: .leading)
                                if let est = tpl.estimatedTime, !est.isEmpty {
                                    Text(est).font(.system(size: 11, design: .rounded)).monospacedDigit().foregroundStyle(.tertiary)
                                        .padding(.horizontal, 5).padding(.vertical, 1).background(.quaternary, in: RoundedRectangle(cornerRadius: 3))
                                        .fixedSize()
                                }
                            }
                            // Row 2: description
                            if let desc = loc.templateDesc(for: tpl), !desc.isEmpty {
                                Text(desc).font(.system(size: 11)).foregroundStyle(.tertiary).lineLimit(3)
                            }
                            // Row 3: devices with icons
                            let deviceNames = tpl.device.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                            if !deviceNames.isEmpty {
                                HStack(spacing: 6) {
                                    ForEach(deviceNames, id: \.self) { d in
                                        Label(loc.localizedDeviceName(d), systemImage: svm.sfSymbol(for: d))
                                            .font(.system(size: 11)).foregroundStyle(.tertiary).labelStyle(.titleAndIcon)
                                            .lineLimit(1).fixedSize(horizontal: true, vertical: false)
                                    }
                                }
                            }
                            // Row 5: important/urgent icons (only if true)
                            if tpl.important || tpl.urgent {
                                HStack(spacing: 8) {
                                    if tpl.important {
                                        Label(loc.t("important_label"), systemImage: "exclamationmark.circle.fill")
                                            .font(.system(size: 11)).foregroundStyle(.red).labelStyle(.titleAndIcon)
                                    }
                                    if tpl.urgent {
                                        Label(loc.t("urgent_label"), systemImage: "flame.fill")
                                            .font(.system(size: 11)).foregroundStyle(.orange).labelStyle(.titleAndIcon)
                                    }
                                }
                            }
                        }
                        .padding(.leading, 8).padding(.vertical, 5)
                        Spacer(minLength: 4)
                        if hoveredId == tpl.id {
                            ActionButtonsView(
                                onEdit: {
                                    vm.sheetConfig = SheetConfig(editing: TodoItem(
                                        name: tpl.name, device: tpl.device, date: nil,
                                        createdDate: TodoViewModel.today, important: tpl.important,
                                        urgent: tpl.urgent, completed: false,
                                        description: tpl.description, estimatedTime: tpl.estimatedTime,
                                        presetKey: tpl.presetKey
                                    ), titleOverride: loc.t("template_edit_title"), templateMode: true, editingTemplateId: tpl.id)
                                },
                                onDelete: { svm.deleteTemplate(tpl) }
                            ).padding(.trailing, 8)
                        }
                    }
                    .padding(.horizontal, 16 - 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(hoveredId == tpl.id ? Color.primary.opacity(0.06) : Color.clear))
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(hoveredId == tpl.id ? Color.primary.opacity(0.2) : Color.primary.opacity(0.06), lineWidth: hoveredId == tpl.id ? 1 : 0.5))
                    .padding(.horizontal, 4).padding(.vertical, 2)
                    .onHover { hovering in withAnimation(.easeInOut(duration: 0.15)) { hoveredId = hovering ? tpl.id : nil } }
                }
                }
            }
            .padding(.top, 0)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
        }
    }
}

// MARK: - Tab 4: Devices
struct DeviceSettingsTab: View {
    @EnvironmentObject var loc: LocalizationManager
    @EnvironmentObject var svm: SettingsViewModel
    @State private var editingId: String?
    @State private var hoveredId: String?
    @State private var isAdding = false
    @State private var editName: String = ""
    @State private var editIcon: String = "desktopcomputer"
    @State private var addBtnHovered: Bool = false

    private func pickerLabel(for icon: String) -> String {
        switch icon {
        case "desktopcomputer": return loc.t("device_computer")
        case "iphone":          return loc.t("device_phone")
        case "ipad":            return loc.t("device_tablet")
        case "applewatch":      return loc.t("device_watch")
        case "note.text":       return loc.t("device_notebook")
        default:                return icon
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Button(action: { isAdding = true; editName = ""; editIcon = "desktopcomputer" }) {
                    Label(loc.t("add_new_device"), systemImage: "plus.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(addBtnHovered ? .primary : .secondary)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Capsule().fill(addBtnHovered ? Color.primary.opacity(0.12) : Color.primary.opacity(0.06)))
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .onHover { h in withAnimation(.easeInOut(duration: 0.15)) { addBtnHovered = h } }
            }
            .frame(height: 30)
            .padding(.top, 6)
            .padding(.trailing, 16)

            Divider().opacity(dividerOpacity).padding(.horizontal, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(svm.devices) { dev in
                        if editingId == dev.id {
                            deviceEditInline
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: dev.sfSymbol).frame(width: 20)
                                Text(loc.localizedDeviceName(dev.name)).font(rowFont)
                                Spacer()
                                if hoveredId == dev.id {
                                    ActionButtonsView(
                                        onEdit: { editName = dev.name; editIcon = dev.sfSymbol; editingId = dev.id },
                                        onDelete: { svm.deleteDevice(dev) }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(minHeight: rowH)
                            .contentShape(.rect)
                            .background(RoundedRectangle(cornerRadius: cr).fill(hoveredId == dev.id ? Color.primary.opacity(0.06) : Color.clear))
                            .onHover { hovering in withAnimation(.easeInOut(duration: 0.15)) { hoveredId = hovering ? dev.id : nil } }
                            Divider().opacity(dividerOpacity).padding(.horizontal, 16)
                        }
                    }

                    if isAdding {
                        deviceEditInline
                    }
                }
                .padding(.top, 0)
            }
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
        }
    }

    private var deviceEditInline: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Picker("", selection: $editIcon) {
                    Label(pickerLabel(for: "desktopcomputer"), systemImage: "desktopcomputer").tag("desktopcomputer")
                    Label(pickerLabel(for: "iphone"), systemImage: "iphone").tag("iphone")
                    Label(pickerLabel(for: "ipad"), systemImage: "ipad").tag("ipad")
                    Label(pickerLabel(for: "applewatch"), systemImage: "applewatch").tag("applewatch")
                    Label(pickerLabel(for: "note.text"), systemImage: "note.text").tag("note.text")
                }.pickerStyle(.menu).labelsHidden()
                TextField(loc.t("device_placeholder"), text: $editName)
                    .textFieldStyle(.roundedBorder).frame(width: 140)
                Spacer()
                Button(loc.t("save")) {
                    let n = editName.trimmingCharacters(in: .whitespaces)
                    guard !n.isEmpty else { return }
                    if let id = editingId, var d = svm.devices.first(where: { $0.id == id }) {
                        d.name = n; d.sfSymbol = editIcon; svm.updateDevice(d); editingId = nil
                    } else {
                        svm.addDevice(n, sfSymbol: editIcon); isAdding = false
                    }
                }.buttonStyle(.borderedProminent).controlSize(.small)
                Button(loc.t("cancel")) { editingId = nil; isAdding = false }.buttonStyle(.plain).font(.system(size: 11))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: cr))
        .padding(.horizontal, 8).padding(.vertical, 4)
    }
}
