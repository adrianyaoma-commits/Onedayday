import SwiftUI
import AppKit

struct TaskRowView: View {
    @EnvironmentObject var vm: TodoViewModel
    @EnvironmentObject var loc: LocalizationManager
    @EnvironmentObject var svm: SettingsViewModel
    let item: TodoItem
    @State private var isHovered = false
    @State private var showFocus = false

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2).fill(qColor).frame(width: 3).padding(.vertical, 6)
            taskContent
            Spacer(minLength: 4)
            if isHovered {
                VStack(alignment: .trailing, spacing: 4) {
                    ActionButtonsView(
                        onEdit: { vm.sheetConfig = SheetConfig(editing: item) },
                        onDelete: { vm.delete(item) }
                    )
                }.padding(.trailing, 8).transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .background(RoundedRectangle(cornerRadius: 8).fill(isHovered ? Color.primary.opacity(0.06) : Color.clear))
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8)
            .strokeBorder(isHovered ? qColor.opacity(0.5) : qColor.opacity(0.15),
                          lineWidth: isHovered ? 1 : 0.5))
        .padding(.horizontal, 4).padding(.vertical, 2)
        .onHover { hovering in withAnimation(.easeInOut(duration: 0.15)) { isHovered = hovering } }
        .onDrag { NSItemProvider(object: item.id as NSString) }
        .contextMenu {
            Button(action: { vm.sheetConfig = SheetConfig(editing: item) }) { Label(loc.t("edit"), systemImage: "pencil") }
            Button(action: { vm.moveToInbox(id: item.id) }) { Label(loc.t("inbox_title"), systemImage: "tray") }
            Divider()
            Button(action: { showFocus = true }) { Label(loc.t("focus_enter_label"), systemImage: "timer") }
            Divider()
            Button(role: .destructive, action: { vm.delete(item) }) { Label(loc.t("delete"), systemImage: "xmark.circle") }
        }
        .sheet(isPresented: $showFocus) { FocusModeView(item: item) }
    }

    private var taskContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Row 1: checkbox + name (wrappable) + duration badge
            HStack(alignment: .top, spacing: 6) {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { vm.toggleComplete(item) }
                    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
                } label: {
                    Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(item.completed ? .green : .secondary)
                        .contentTransition(.symbolEffect(.replace))
                }.buttonStyle(.plain).fixedSize()
                Text(loc.presetName(for: item)).font(.system(size: 14, weight: .semibold, design: .default))
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(item.completed ? .secondary : .primary).strikethrough(item.completed)
                let dur = item.durationDisplay
                if !dur.isEmpty {
                    Text(dur).font(.system(size: 11, design: .rounded)).monospacedDigit().foregroundStyle(.tertiary)
                        .padding(.horizontal, 5).padding(.vertical, 1).background(.quaternary, in: RoundedRectangle(cornerRadius: 3))
                        .fixedSize()
                }
            }
            // Row 2: description (wrappable)
            if let desc = loc.presetDesc(for: item), !desc.isEmpty {
                Text(desc).font(.system(size: 11)).foregroundStyle(.tertiary).lineLimit(3)
                    .padding(.leading, 22)
            }
            // Row 3: devices (individual no-wrap, group wrappable)
            let deviceNames = item.device.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            if !deviceNames.isEmpty {
                HStack(spacing: 6) {
                    ForEach(deviceNames, id: \.self) { d in
                        Label(loc.localizedDeviceName(d), systemImage: svm.sfSymbol(for: d))
                            .font(.system(size: 11)).foregroundStyle(.tertiary).labelStyle(.titleAndIcon)
                            .lineLimit(1).fixedSize(horizontal: true, vertical: false)
                    }
                }
                .padding(.leading, 22)
            }
            // Row 4: file link (filename wrappable)
            if let path = item.filePath, !path.isEmpty {
                fileLinkView(path: path).padding(.leading, 22)
            }
        }.padding(.leading, 8).padding(.vertical, 5)
    }

    private func fileLinkView(path: String) -> some View {
        let url = URL(fileURLWithPath: path); let fname = url.lastPathComponent
        var isDir: ObjCBool = false; _ = FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        return HStack(spacing: 4) {
            Image(systemName: isDir.boolValue ? "folder.fill" : "doc.fill").font(.system(size: 11)).foregroundStyle(.tertiary)
            Text(fname).font(.system(size: 11)).foregroundStyle(.tertiary).lineLimit(2).truncationMode(.middle)
            Button(loc.t("open")) { NSWorkspace.shared.open(url) }
                .buttonStyle(.plain).font(.system(size: 11, weight: .medium)).foregroundStyle(.blue)
        }
    }

    private var qColor: Color { item.quadrant.themeColor }
}

/// Reusable hover action buttons — pencil.circle.fill (edit) + xmark.circle.fill (delete)
/// Vertical layout, positioned at the far right of list rows.
struct ActionButtonsView: View {
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 2) {
            Button(action: onEdit) {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 16))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                    .frame(width: 26, height: 26)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.red)
                    .frame(width: 26, height: 26)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
