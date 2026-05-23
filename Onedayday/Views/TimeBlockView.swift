import SwiftUI

struct TimeBlockView: View {
    @EnvironmentObject var vm: TodoViewModel
    @EnvironmentObject var loc: LocalizationManager
    let item: TodoItem
    let hourHeight: CGFloat
    @State private var isHovered = false
    @State private var topDragDelta: CGFloat? = nil
    @State private var bottomDragDelta: CGFloat? = nil

    private let topPadding: CGFloat = 4
    private let leftPad: CGFloat = 40
    private let rightPad: CGFloat = 10
    private let radius: CGFloat = 5
    private let accentW: CGFloat = 3
    private let handleH: CGFloat = 8

    private var minuteHeight: CGFloat { hourHeight / 60.0 }
    private var sMin: Int { item.startHour ?? 0 }
    private var eMin: Int { item.endHour ?? max(0, min(1440, sMin + 60)) }
    private var blockY: CGFloat { CGFloat(sMin) * minuteHeight + topPadding }
    private var blockHeight: CGFloat { max(hourHeight * 0.28, CGFloat(max(5, eMin - sMin)) * minuteHeight - 2) }
    private var blockColor: Color { item.quadrant.themeColor }

    private var topGhostY: CGFloat {
        guard let dy = topDragDelta else { return blockY }
        let ns = TodoViewModel.snap5(sMin + Int(round(dy / minuteHeight / 5) * 5))
        return CGFloat(max(0, ns)) * minuteHeight + topPadding
    }
    private var topGhostH: CGFloat {
        guard let dy = topDragDelta else { return blockHeight }
        let ns = TodoViewModel.snap5(sMin + Int(round(dy / minuteHeight / 5) * 5))
        return CGFloat(max(5, eMin - max(0, ns))) * minuteHeight - 2
    }
    private var bottomGhostH: CGFloat {
        guard let dy = bottomDragDelta else { return blockHeight }
        let ne = TodoViewModel.snap5(eMin + Int(round(dy / minuteHeight / 5) * 5))
        return CGFloat(max(5, ne - sMin)) * minuteHeight - 2
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if topDragDelta != nil {
                ghostBlock()
                    .frame(height: topGhostH)
                    .padding(.leading, leftPad)
                    .padding(.trailing, rightPad)
                    .padding(.top, topGhostY)
                    .allowsHitTesting(false)
            }
            if bottomDragDelta != nil {
                ghostBlock()
                    .frame(height: bottomGhostH)
                    .padding(.leading, leftPad)
                    .padding(.trailing, rightPad)
                    .padding(.top, blockY)
                    .allowsHitTesting(false)
            }

            // Main block
            blockBody
                .frame(height: blockHeight)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 2)
                .background(blockColor.opacity(isHovered ? 0.22 : 0.10), in: RoundedRectangle(cornerRadius: radius))
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(blockColor)
                        .frame(width: accentW)
                        .padding(.vertical, 2)
                }
                // Resize handles — overlays covering full visual border width
                .overlay(alignment: .top) { resizeHandle(isTop: true) }
                .overlay(alignment: .bottom) { resizeHandle(isTop: false) }
                .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(
                    isHovered ? blockColor.opacity(0.6) : blockColor.opacity(0.25), lineWidth: isHovered ? 1.2 : 0.5))
                .clipped()
                .opacity((topDragDelta != nil || bottomDragDelta != nil) ? 0.35 : 1.0)
                .onHover { hovering in withAnimation(.easeInOut(duration: 0.12)) { isHovered = hovering } }
                .onTapGesture(count: 1) { vm.sheetConfig = SheetConfig(editing: item) }
                .contextMenu {
                    Button(loc.t("edit")) { vm.sheetConfig = SheetConfig(editing: item) }
                    Button(loc.t("menu_remove_timeline")) { vm.removeFromTimeline(id: item.id) }
                }
                .padding(.leading, leftPad)
                .padding(.trailing, rightPad)
                .padding(.top, blockY)
        }
    }

    // MARK: - Ghost block
    private func ghostBlock() -> some View {
        blockBody
            .padding(.horizontal, 2)
            .background(blockColor.opacity(0.15), in: RoundedRectangle(cornerRadius: radius))
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(blockColor.opacity(0.7))
                    .frame(width: accentW)
                    .padding(.vertical, 2)
            }
            .overlay(RoundedRectangle(cornerRadius: radius)
                .strokeBorder(blockColor.opacity(0.7), style: StrokeStyle(lineWidth: 2, dash: [4, 3])))
            .frame(maxWidth: .infinity)
    }

    // MARK: - Block body
    private var blockBody: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(loc.presetName(for: item))
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(2)
                .foregroundStyle(.primary)
            if let desc = loc.presetDesc(for: item), !desc.isEmpty {
                Text(desc)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Text("\(item.displayStart) – \(item.displayEnd)")
                .font(.system(size: 10, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.tertiary)
        }
        .padding(.leading, 8)
        .padding(.vertical, handleH / 2 + 2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Resize handle (top: true = start, false = end)
    private func resizeHandle(isTop: Bool) -> some View {
        Color.clear
            .frame(height: handleH)
            .contentShape(.rect)
            .onHover { hovering in
                if hovering { NSCursor.resizeUpDown.push() } else { NSCursor.pop() }
            }
            .gesture(
                DragGesture(minimumDistance: 3, coordinateSpace: .named("TimelineSpace"))
                    .onChanged { value in
                        if isTop { topDragDelta = value.translation.height }
                        else     { bottomDragDelta = value.translation.height }
                    }
                    .onEnded { value in
                        if isTop { topDragDelta = nil } else { bottomDragDelta = nil }
                        NSCursor.pop()
                        let deltaMin = Int(round(value.translation.height / minuteHeight / 5)) * 5
                        guard deltaMin != 0 else { return }
                        if isTop {
                            let ns = TodoViewModel.snap5(sMin + deltaMin)
                            guard ns >= 0, ns < eMin else { return }
                            vm.updateTimelineItem(id: item.id, startMin: ns, endMin: eMin)
                        } else {
                            let ne = TodoViewModel.snap5(eMin + deltaMin)
                            guard ne > sMin, ne <= 1440 else { return }
                            vm.updateTimelineItem(id: item.id, startMin: sMin, endMin: ne)
                        }
                    }
            )
    }
}
