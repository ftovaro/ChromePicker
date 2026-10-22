import AppKit
import SwiftUI

final class PickerSelection: ObservableObject {
    @Published var index = 0
}

/// Borderless panel that takes keyboard focus without activating the app, like Spotlight.
final class PickerPanel: NSPanel {
    var onKeyDown: ((NSEvent) -> Bool)?

    override var canBecomeKey: Bool { true }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown, onKeyDown?(event) == true { return }
        super.sendEvent(event)
    }
}

final class PickerWindowController: NSWindowController, NSWindowDelegate {

    private let selection = PickerSelection()
    private let hostingView = NSHostingView(rootView: AnyView(EmptyView()))
    private var url: URL?
    private var profiles: [ChromeProfile] = []

    init() {
        let panel = PickerPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.contentView = hostingView

        super.init(window: panel)

        panel.delegate = self
        panel.onKeyDown = { [weak self] event in self?.handleKeyDown(event) ?? false }
    }

    required init?(coder: NSCoder) { fatalError() }

    func show(url: URL) {
        guard let panel = window else { return }

        self.url = url
        profiles = ChromeProfileReader.profiles()
        selection.index = 0

        hostingView.rootView = AnyView(PickerView(
            url: url,
            profiles: profiles,
            selection: selection,
            onSelect: { [weak self] index in self?.select(index) }
        ))
        panel.setContentSize(hostingView.fittingSize)
        positionNearMouse()
        panel.makeKeyAndOrderFront(nil)
        panel.invalidateShadow()
    }

    func dismiss() {
        url = nil
        window?.orderOut(nil)
    }

    func windowDidResignKey(_ notification: Notification) {
        dismiss()
    }

    private func select(_ index: Int) {
        guard let url, profiles.indices.contains(index) else { return }
        ChromeProfileReader.open(url, in: profiles[index])
        dismiss()
    }

    private func handleKeyDown(_ event: NSEvent) -> Bool {
        switch event.keyCode {
        case 53: // Escape
            dismiss()
        case 36, 76: // Return, keypad Enter
            select(selection.index)
        case 125: // Down arrow
            selection.index = min(selection.index + 1, max(profiles.count - 1, 0))
        case 126: // Up arrow
            selection.index = max(selection.index - 1, 0)
        default:
            guard let number = Int(event.charactersIgnoringModifiers ?? ""),
                  profiles.indices.contains(number - 1) else { return false }
            select(number - 1)
        }
        return true
    }

    private func positionNearMouse() {
        guard let panel = window else { return }

        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return }

        let size = panel.frame.size
        let margin: CGFloat = 8
        let x = min(max(mouse.x - size.width / 2, visible.minX + margin), visible.maxX - size.width - margin)
        let y = min(max(mouse.y - size.height - 12, visible.minY + margin), visible.maxY - size.height - margin)
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

// MARK: - Views

private struct PickerView: View {
    let url: URL
    let profiles: [ChromeProfile]
    @ObservedObject var selection: PickerSelection
    let onSelect: (Int) -> Void

    private var urlSummary: String {
        url.isFileURL ? url.lastPathComponent : (url.host ?? url.absoluteString)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Open in Chrome")
                    .font(.system(size: 13, weight: .semibold))
                Text(urlSummary)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)

            if profiles.isEmpty {
                Text("No Chrome profiles found.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(8)
            }

            VStack(spacing: 2) {
                ForEach(Array(profiles.enumerated()), id: \.element.id) { index, profile in
                    ProfileRow(
                        profile: profile,
                        shortcut: index < 9 ? index + 1 : nil,
                        isSelected: index == selection.index
                    )
                    .contentShape(Rectangle())
                    .onHover { if $0 { selection.index = index } }
                    .onTapGesture { onSelect(index) }
                }
            }
        }
        .padding(8)
        .frame(width: 320)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.1))
        )
    }
}

private struct ProfileRow: View {
    let profile: ChromeProfile
    let shortcut: Int?
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            avatar
                .frame(width: 28, height: 28)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(Color(nsColor: profile.color), lineWidth: 2))

            VStack(alignment: .leading, spacing: 1) {
                Text(profile.displayName)
                    .font(.system(size: 13, weight: .medium))
                if let email = profile.email {
                    Text(email)
                        .font(.system(size: 11))
                        .opacity(0.7)
                }
            }
            .lineLimit(1)

            Spacer()

            if let shortcut {
                Text("\(shortcut)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .opacity(0.6)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .background(
            isSelected ? Color.accentColor : Color.clear,
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }

    @ViewBuilder private var avatar: some View {
        if let picture = profile.picture {
            Image(nsImage: picture)
                .resizable()
                .scaledToFill()
        } else {
            Color(nsColor: profile.color)
                .overlay(
                    Text(profile.displayName.prefix(1).uppercased())
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                )
        }
    }
}
