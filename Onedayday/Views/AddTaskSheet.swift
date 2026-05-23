import SwiftUI
import AppKit

// MARK: - Hardcoded skeleton constants
private let IH: CGFloat = 36
private let LH: CGFloat = 80
private let DH: CGFloat = 80   // description height
private let BG = Color.primary.opacity(0.08)
private let CR: CGFloat = 6
private let FONT: Font = .system(size: 13, weight: .regular)

struct AddTaskSheet: View {
    @EnvironmentObject var vm: TodoViewModel
    @EnvironmentObject var loc: LocalizationManager
    @EnvironmentObject var svm: SettingsViewModel

    var quadrant: TodoItem.Quadrant?
    var date: String?
    var editing: TodoItem?
    var titleOverride: String? = nil
    var templateMode: Bool = false
    var editingTemplateId: String? = nil

    @State private var name: String = ""
    @State private var taskDate: Date = Date()
    @State private var important: Bool
    @State private var urgent: Bool
    @State private var isInbox: Bool = false
    @State private var showDatePopover = false
    @State private var showTimeError = false

    @State private var selectedDevices: Set<String> = []
    @State private var filePath: String = ""
    @State private var fileName: String = ""
    @State private var isFolder: Bool = false
    @State private var desc: String = ""
    @State private var startTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @State private var endTime: Date = Calendar.current.date(from: DateComponents(hour: 10, minute: 0)) ?? Date()
    @State private var startHourString: String = "09"
    @State private var startMinString: String = "00"
    @State private var endHourString: String = "10"
    @State private var endMinString: String = "00"

    private let maxDescLength = 500

    init(quadrant: TodoItem.Quadrant? = nil, date: String? = TodoViewModel.today, editing: TodoItem? = nil, titleOverride: String? = nil, templateMode: Bool = false, editingTemplateId: String? = nil) {
        self.quadrant = quadrant; self.date = date; self.editing = editing; self.titleOverride = titleOverride; self.templateMode = templateMode; self.editingTemplateId = editingTemplateId
        let isImp = editing?.important ?? (quadrant == .importantUrgent || quadrant == .importantNotUrgent)
        let isUrg = editing?.urgent ?? (quadrant == .importantUrgent || quadrant == .notImportantUrgent)
        self._important = State(initialValue: isImp); self._urgent = State(initialValue: isUrg)
        self._isInbox = State(initialValue: date == nil)
        if let d = date { self._taskDate = State(initialValue: Self.dateFrom(string: d)) }
        if let e = editing {
            self._name = State(initialValue: e.name); self._isInbox = State(initialValue: e.date == nil)
            if let d = e.date { self._taskDate = State(initialValue: Self.dateFrom(string: d)) }
            let devs = e.device.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            self._selectedDevices = State(initialValue: Set(devs))
            self._desc = State(initialValue: e.description ?? "")
            if let fp = e.filePath, !fp.isEmpty {
                self._filePath = State(initialValue: fp)
                self._fileName = State(initialValue: URL(fileURLWithPath: fp).lastPathComponent)
                var isDir: ObjCBool = false
                _ = FileManager.default.fileExists(atPath: fp, isDirectory: &isDir)
                self._isFolder = State(initialValue: isDir.boolValue)
            }
            if let sMin = e.startHour { self._startTime = State(initialValue: TodoViewModel.dateFromMinutes(sMin)) }
            if let eMin = e.endHour   { self._endTime   = State(initialValue: TodoViewModel.dateFromMinutes(eMin)) }
            let cal = Calendar.current
            self._startHourString = State(initialValue: String(format: "%02d", cal.component(.hour, from: self._startTime.wrappedValue)))
            self._startMinString  = State(initialValue: String(format: "%02d", nearest5(cal.component(.minute, from: self._startTime.wrappedValue))))
            self._endHourString   = State(initialValue: String(format: "%02d", cal.component(.hour, from: self._endTime.wrappedValue)))
            self._endMinString    = State(initialValue: String(format: "%02d", nearest5(cal.component(.minute, from: self._endTime.wrappedValue))))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Quick Templates (capsule pills) ──
            if editing == nil, !svm.templates.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(svm.templates) { tpl in
                            Button(action: { applyTemplate(tpl) }) {
                                Text(loc.templateName(for: tpl)).font(FONT)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(Color.primary.opacity(0.1), in: Capsule(style: .continuous))
                            }.buttonStyle(.plain)
                        }
                    }.padding(.horizontal, 2)
                }.padding(.bottom, 16)
                Divider().opacity(0.15).padding(.bottom, 16)
            }

            // ── Title ──
            Text(titleOverride ?? (editing != nil ? loc.t("edit") : loc.t("new_task")))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.bottom, 18)

            // ═══ Task Name * ═══
            row(label: loc.t("name_label"), required: true) {
                TextField(loc.t("name_placeholder"), text: $name)
                    .textFieldStyle(.plain).font(FONT).foregroundStyle(.primary)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .leading).frame(height: IH)
                    .background(BG, in: RoundedRectangle(cornerRadius: CR)).overlay(RoundedRectangle(cornerRadius: CR).stroke(Color.gray.opacity(0.2), lineWidth: 1))
            }

            // ═══ Date * + Inbox toggle ═══
            row(label: loc.t("date_label"), required: true) {
                HStack(spacing: 6) {
                    if isInbox {
                        HStack {
                            Text("--").font(.system(size: 13, design: .monospaced)).foregroundStyle(.tertiary)
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, alignment: .leading).frame(height: IH)
                        .background(BG, in: RoundedRectangle(cornerRadius: CR)).overlay(RoundedRectangle(cornerRadius: CR).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    } else {
                        Button { showDatePopover.toggle() } label: {
                            HStack {
                                Text(TodoViewModel.dateString(from: taskDate))
                                    .font(.system(size: 13, design: .monospaced)).foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "calendar").font(.system(size: 13)).foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity, alignment: .leading).frame(height: IH)
                            .background(BG, in: RoundedRectangle(cornerRadius: CR)).overlay(RoundedRectangle(cornerRadius: CR).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        }.buttonStyle(.plain)
                        .popover(isPresented: $showDatePopover, arrowEdge: .bottom) {
                            CustomCalendarView(selectedDate: $taskDate).padding(8).frame(width: 240)
                        }
                    }
                    if editing == nil {
                        Toggle(loc.t("inbox_no_date"), isOn: $isInbox)
                            .toggleStyle(.checkbox).controlSize(.small).fixedSize()
                    }
                }
            }

            // ═══ Priority ═══
            row(label: "") {
                HStack(spacing: 12) {
                    Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { important.toggle() } }) {
                        HStack(spacing: 4) {
                            Image(systemName: important ? "exclamationmark.circle.fill" : "exclamationmark.circle")
                            Text(loc.t("important_label"))
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(important ? .red : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(important ? Color.red.opacity(0.15) : Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .disabled(quadrant != nil && editing == nil)

                    Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { urgent.toggle() } }) {
                        HStack(spacing: 4) {
                            Image(systemName: urgent ? "flame.fill" : "flame")
                            Text(loc.t("urgent_label"))
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(urgent ? .orange : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(urgent ? Color.orange.opacity(0.15) : Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .disabled(quadrant != nil && editing == nil)
                }
            }

            Divider().opacity(0.15).padding(.vertical, 14)

            // ═══ Device (multi-select capsule matrix) ═══
            HStack(spacing: 12) {
                Text(loc.t("device_label"))
                    .font(.system(size: 13, weight: .regular)).foregroundStyle(.secondary)
                    .frame(width: LH, alignment: .trailing)

                let devices = svm.devices.isEmpty ? DeviceConfig.defaults : svm.devices
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(devices) { dev in
                            let isSelected = selectedDevices.contains(dev.name)
                            Button(action: {
                                if isSelected { selectedDevices.remove(dev.name) }
                                else { selectedDevices.insert(dev.name) }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: dev.sfSymbol).font(.system(size: 11))
                                    Text(loc.localizedDeviceName(dev.name))
                                }
                                .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                                .foregroundColor(isSelected ? .white : .secondary)
                                .padding(.horizontal, 12)
                                .frame(height: 28)
                                .background(isSelected ? Color.blue : Color.primary.opacity(0.08))
                                .cornerRadius(14)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(height: IH).frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 7)

            // ═══ Time Slot ═══
            HStack(spacing: 12) {
                Text(loc.t("time_slot"))
                    .font(.system(size: 13, weight: .regular)).foregroundStyle(.secondary)
                    .frame(width: LH, alignment: .trailing)

                HStack(spacing: 6) {
                    timeField(hourStr: $startHourString, minStr: $startMinString, date: $startTime)
                    Text(loc.t("time_separator"))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                    timeField(hourStr: $endHourString, minStr: $endMinString, date: $endTime)
                    Text(durationText)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.8))
                        .padding(.leading, 8)
                        .frame(minWidth: 50, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 7)

            // ═══ File (fills full width, folder icon) ═══
            row(label: loc.t("file_label")) {
                Button(action: pickFile) {
                    HStack {
                        if fileName.isEmpty {
                            Text(loc.t("choose_file")).font(.system(size: 13, weight: .regular)).foregroundStyle(.secondary)
                        } else {
                            Label(fileName, systemImage: isFolder ? "folder.fill" : "doc.fill")
                                .font(.system(size: 13, weight: .regular)).foregroundStyle(.secondary).lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "folder").font(.system(size: 13)).foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .leading).frame(height: IH)
                    .background(BG, in: RoundedRectangle(cornerRadius: CR)).overlay(RoundedRectangle(cornerRadius: CR).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            // ═══ Description ═══
            HStack(alignment: .top, spacing: 12) {
                Text(loc.t("description_label"))
                    .font(.system(size: 13, weight: .regular)).foregroundStyle(.secondary)
                    .frame(width: LH, alignment: .trailing)
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 4) {
                    TextField(loc.t("task_desc_placeholder"), text: $desc, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(FONT).foregroundStyle(.primary)
                        .lineLimit(4...)
                        .padding(8)
                        .frame(minHeight: DH)
                        .background(BG, in: RoundedRectangle(cornerRadius: CR))
                        .overlay(RoundedRectangle(cornerRadius: CR).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        .onChange(of: desc) { _, new in
                            if new.count > maxDescLength { desc = String(new.prefix(maxDescLength)) }
                        }
                    Text("\(desc.count)/\(maxDescLength)")
                        .font(.system(size: 11, design: .monospaced)).foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 7)

            // ── Actions ──
            HStack(spacing: 14) {
                Spacer()
                Button(loc.t("cancel")) { vm.sheetConfig = nil }
                    .buttonStyle(.plain).foregroundStyle(.secondary).keyboardShortcut(.escape, modifiers: [])
                Button(loc.t("save")) { commit() }
                    .buttonStyle(.borderedProminent).controlSize(.small)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .keyboardShortcut(.return, modifiers: [])
            }.padding(.top, 22)
        }
        .padding(28)
        .frame(width: 500)
        .onAppear { resolvePreset() }
        .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.06), lineWidth: 0.5))
        .alert(loc.t("time_error_title"), isPresented: $showTimeError) {
            Button(loc.t("ok")) { }
        } message: {
            Text(loc.t("time_error_msg"))
        }
    }

    // MARK: - Duration display
    private var durationText: String {
        let start = (Int(startHourString) ?? 0) * 60 + (Int(startMinString) ?? 0)
        var end = (Int(endHourString) ?? 0) * 60 + (Int(endMinString) ?? 0)
        if end < start { end += 1440 }
        let diff = end - start
        if diff == 0 { return "0m" }
        let h = diff / 60
        let m = diff % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    // MARK: - Single-line row skeleton (uniform HStack)
    private func row<Content: View>(label: String, required: Bool = false,
                                     @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(spacing: 2) {
                if required { Text("*").font(.system(size: 13, weight: .regular)).foregroundStyle(.red) }
                Text(label).font(.system(size: 13, weight: .regular)).foregroundStyle(.secondary)
            }
            .frame(width: LH, alignment: .trailing)
            content()
        }
        .padding(.vertical, 7)
    }

    // MARK: - Time helpers
    private func formatTime(_ date: Date) -> String {
        let cal = Calendar.current
        let h = cal.component(.hour, from: date)
        let m = cal.component(.minute, from: date)
        return String(format: "%02d:%02d", h, m)
    }

    // MARK: - Inline time field
    private func timeField(hourStr: Binding<String>, minStr: Binding<String>,
                            date: Binding<Date>) -> some View {
        HStack(spacing: 2) {
            TextField("", text: hourStr)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .monospacedDigit()
                .frame(width: 36, height: 28)
                .background(Color.primary.opacity(0.08))
                .cornerRadius(6)
                .onChange(of: hourStr.wrappedValue) { _, new in
                    let filtered = new.filter { $0.isNumber }
                    let limited = String(filtered.prefix(2))
                    if limited != new { hourStr.wrappedValue = limited }
                    if let num = Int(limited), num > 23 { hourStr.wrappedValue = "23" }
                    syncTimeFromStrings(hourStr: hourStr, minStr: minStr, date: date)
                }
            Text(":")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.horizontal, 2)
            TextField("", text: minStr)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .monospacedDigit()
                .frame(width: 36, height: 28)
                .background(Color.primary.opacity(0.08))
                .cornerRadius(6)
                .onChange(of: minStr.wrappedValue) { _, new in
                    let filtered = new.filter { $0.isNumber }
                    let limited = String(filtered.prefix(2))
                    if limited != new { minStr.wrappedValue = limited }
                    if let num = Int(limited), num > 59 { minStr.wrappedValue = "59" }
                    syncTimeFromStrings(hourStr: hourStr, minStr: minStr, date: date)
                }
        }
    }

    // MARK: - Actions
    private func applyTemplate(_ tpl: TaskTemplate) {
        name = loc.templateName(for: tpl); important = tpl.important; urgent = tpl.urgent
        selectedDevices = Set(tpl.device.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }); desc = loc.templateDesc(for: tpl) ?? ""
        if let est = tpl.estimatedTime, !est.isEmpty {
            let totalMinutes = parseDuration(est)
            if totalMinutes > 0, let newEnd = Calendar.current.date(byAdding: .minute, value: totalMinutes, to: startTime) {
                endTime = newEnd
                let cal = Calendar.current
                endHourString = String(format: "%02d", cal.component(.hour, from: newEnd))
                endMinString = String(format: "%02d", nearest5(cal.component(.minute, from: newEnd)))
            }
        }
    }
    private func parseDuration(_ s: String) -> Int {
        var total = 0
        let parts = s.lowercased().split(separator: " ")
        for part in parts {
            let str = String(part)
            if str.hasSuffix("h"), let v = Int(str.dropLast(1)) { total += v * 60 }
            else if str.hasSuffix("m"), let v = Int(str.dropLast(1)) { total += v }
        }
        return total
    }
    private func pickFile() {
        let panel = NSOpenPanel(); panel.canChooseFiles = true; panel.canChooseDirectories = true; panel.allowsMultipleSelection = false
        panel.begin { response in
            if response == .OK, let url = panel.url {
                filePath = url.path; fileName = url.lastPathComponent
                var isDir: ObjCBool = false
                _ = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir); isFolder = isDir.boolValue
            }
        }
    }
    private func commit() {
        let trimmed = name.trimmingCharacters(in: .whitespaces); guard !trimmed.isEmpty else { return }
        // Compute time slot values (always, for both template and task)
        let startMin = TodoViewModel.minutesFromDate(startTime)
        let endMin = TodoViewModel.minutesFromDate(endTime)
        if endMin <= startMin { showTimeError = true; return }
        let snapS = TodoViewModel.snap5(startMin); let snapE = TodoViewModel.snap5(endMin)
        let diff = snapE - snapS; let h = diff / 60; let m = diff % 60
        let durStr: String = {
            if h > 0 && m > 0 { return "\(h)h \(m)m" }
            if h > 0 { return "\(h)h" }
            return "\(m)m"
        }()

        if templateMode {
            let dev = selectedDevices.sorted().joined(separator: ", ")
            if let tid = editingTemplateId, let idx = svm.templates.firstIndex(where: { $0.id == tid }) {
                var updated = svm.templates[idx]
                updated.name = trimmed; updated.important = important; updated.urgent = urgent
                updated.device = dev.isEmpty ? "Mac" : dev
                updated.description = desc.isEmpty ? nil : desc
                updated.estimatedTime = durStr
                svm.updateTemplate(updated)
            } else {
                svm.addTemplate(TaskTemplate(name: trimmed, important: important, urgent: urgent,
                    device: dev.isEmpty ? "Mac" : dev, description: desc.isEmpty ? nil : desc, estimatedTime: durStr))
            }
            vm.sheetConfig = nil
            return
        }
        let dateStr: String? = isInbox ? nil : TodoViewModel.dateString(from: taskDate)
        if var e = editing {
            e.name = trimmed; e.device = selectedDevices.sorted().joined(separator: ", "); e.filePath = filePath.isEmpty ? nil : filePath
            e.important = important; e.urgent = urgent; e.date = dateStr
            e.description = desc.isEmpty ? nil : desc; e.estimatedTime = durStr
            e.startHour = isInbox ? nil : snapS; e.endHour = isInbox ? nil : snapE
            vm.update(e)
        } else {
            vm.add(TodoItem(name: trimmed, filePath: filePath.isEmpty ? nil : filePath, device: selectedDevices.sorted().joined(separator: ", "),
                date: dateStr, createdDate: dateStr ?? TodoViewModel.today, important: important, urgent: urgent,
                completed: false, description: desc.isEmpty ? nil : desc, estimatedTime: durStr,
                startHour: isInbox ? nil : snapS,
                endHour: isInbox ? nil : snapE))
        }
        vm.sheetConfig = nil
    }
    private func syncTimeFromStrings(hourStr: Binding<String>, minStr: Binding<String>, date: Binding<Date>) {
        let h = min(max(Int(hourStr.wrappedValue) ?? 0, 0), 23)
        let m = nearest5(min(max(Int(minStr.wrappedValue) ?? 0, 0), 59))
        let cal = Calendar.current
        if let d = cal.date(from: DateComponents(hour: h, minute: m)) {
            date.wrappedValue = d
        }
        hourStr.wrappedValue = String(format: "%02d", h)
        minStr.wrappedValue = String(format: "%02d", m)
    }
    private func nearest5(_ v: Int) -> Int { Int(round(Double(v) / 5.0) * 5) }
    private func resolvePreset() {
        guard let e = editing, e.presetKey != nil else { return }
        name = loc.presetName(for: e)
        if let d = loc.presetDesc(for: e) { desc = d }
    }
    private static func dateFrom(string: String) -> Date {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX")
        return f.date(from: string) ?? Date()
    }
}

