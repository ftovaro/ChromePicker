import AppKit
import ServiceManagement

extension UserDefaults {
    var isPickerPaused: Bool {
        get { bool(forKey: "isPickerPaused") }
        set { set(newValue, forKey: "isPickerPaused") }
    }
}

final class StatusItemController: NSObject, NSMenuDelegate {

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()

    override init() {
        super.init()
        statusItem.button?.image = NSImage(systemSymbolName: "arrow.triangle.branch", accessibilityDescription: "ChromePicker")
        menu.delegate = self
        statusItem.menu = menu
        updateIcon()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        let isPaused = UserDefaults.standard.isPickerPaused

        menu.removeAllItems()
        menu.addItem(withTitle: isPaused ? "ChromePicker is paused" : "ChromePicker is active", action: nil, keyEquivalent: "")
        menu.addItem(.separator())
        addItem("Pause Picker", action: #selector(togglePause), isOn: isPaused)
        addItem("Launch at Login", action: #selector(toggleLaunchAtLogin), isOn: SMAppService.mainApp.status == .enabled)
        if !isDefaultBrowser {
            addItem("Set as Default Browser…", action: #selector(setAsDefaultBrowser))
        }
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit ChromePicker", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    }

    /// Fallback for when the menu bar is too crowded and the status item is hidden behind the notch.
    func showMenuAtMouse() {
        NSApp.activate(ignoringOtherApps: true)
        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }

    private func addItem(_ title: String, action: Selector, isOn: Bool = false) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.state = isOn ? .on : .off
        menu.addItem(item)
    }

    private func updateIcon() {
        statusItem.button?.appearsDisabled = UserDefaults.standard.isPickerPaused
    }

    private var isDefaultBrowser: Bool {
        guard let handler = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https://example.com")!) else {
            return false
        }
        return handler.resolvingSymlinksInPath() == Bundle.main.bundleURL.resolvingSymlinksInPath()
    }

    @objc private func togglePause() {
        UserDefaults.standard.isPickerPaused.toggle()
        updateIcon()
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSApp.activate(ignoringOtherApps: true)
            NSAlert(error: error).runModal()
        }
    }

    @objc private func setAsDefaultBrowser() {
        // macOS asks the user to confirm; https follows the http choice.
        NSWorkspace.shared.setDefaultApplication(at: Bundle.main.bundleURL, toOpenURLsWithScheme: "http") { _ in }
    }
}
