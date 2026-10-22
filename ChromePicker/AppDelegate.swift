import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private lazy var picker = PickerWindowController()
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItemController = StatusItemController()
        _ = ChromeProfileReader.profiles()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        statusItemController?.showMenuAtMouse()
        return false
    }

    // Receives both http(s) links and opened HTML files.
    func application(_ application: NSApplication, open urls: [URL]) {
        if UserDefaults.standard.isPickerPaused {
            urls.forEach { ChromeProfileReader.open($0, in: nil) }
        } else if let url = urls.last {
            picker.show(url: url)
        }
    }
}
