import AppKit

struct ChromeProfile: Identifiable {
    let directoryName: String   // e.g. "Default", "Profile 1"
    let displayName: String     // e.g. "Personal", "Work"
    let email: String?
    let color: NSColor
    let picture: NSImage?

    var id: String { directoryName }
}

enum ChromeProfileReader {

    static let chromeBundleIdentifier = "com.google.Chrome"

    private static let chromeDataURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/Google/Chrome")
    private static let localStateURL = chromeDataURL.appendingPathComponent("Local State")

    private static var cachedProfiles: [ChromeProfile] = []
    private static var cachedModificationDate: Date?
    private(set) static var loadError: String?

    static func profiles() -> [ChromeProfile] {
        let modified = try? localStateURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
        if cachedProfiles.isEmpty || modified != cachedModificationDate {
            cachedProfiles = readProfiles()
            cachedModificationDate = modified
        }
        return cachedProfiles
    }

    /// Opens the URL in the given profile, or in Chrome's last used profile when `profile` is nil.
    static func open(_ url: URL, in profile: ChromeProfile?) {
        guard let chromeURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: chromeBundleIdentifier) else {
            NSSound.beep()
            return
        }

        guard let profile else {
            NSWorkspace.shared.open([url], withApplicationAt: chromeURL, configuration: NSWorkspace.OpenConfiguration())
            return
        }

        // A new Chrome process hands the URL and profile to the running instance, then exits.
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [
            "-n", "-a", chromeURL.path,
            "--args", "--profile-directory=\(profile.directoryName)", url.absoluteString,
        ]
        try? process.run()
    }

    private static func readProfiles() -> [ChromeProfile] {
        let data: Data
        do {
            data = try Data(contentsOf: localStateURL)
        } catch {
            loadError = "Can't read \(localStateURL.path): \(error.localizedDescription)"
            return []
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let profileSection = json["profile"] as? [String: Any],
              let infoCache = profileSection["info_cache"] as? [String: [String: Any]] else {
            loadError = "Unexpected format in \(localStateURL.path)"
            return []
        }
        loadError = nil

        let order = (profileSection["profiles_order"] as? [String] ?? []).filter { infoCache[$0] != nil }
        let unordered = infoCache.keys.filter { !order.contains($0) }.sorted()

        return (order + unordered).compactMap { directoryName in
            guard let info = infoCache[directoryName] else { return nil }

            let name = info["name"] as? String
            let email = info["user_name"] as? String
            let colorValue = (info["profile_highlight_color"] as? NSNumber)?.int64Value
            let pictureURL = chromeDataURL.appendingPathComponent("\(directoryName)/Google Profile Picture.png")

            return ChromeProfile(
                directoryName: directoryName,
                displayName: name?.isEmpty == false ? name! : directoryName,
                email: email?.isEmpty == false ? email : nil,
                color: colorValue.map(color(fromARGB:)) ?? .systemGray,
                picture: NSImage(contentsOf: pictureURL)
            )
        }
    }

    // Chrome stores colors as signed 32-bit ARGB integers.
    private static func color(fromARGB value: Int64) -> NSColor {
        let argb = UInt32(truncatingIfNeeded: value)
        return NSColor(
            srgbRed: CGFloat((argb >> 16) & 0xFF) / 255,
            green: CGFloat((argb >> 8) & 0xFF) / 255,
            blue: CGFloat(argb & 0xFF) / 255,
            alpha: 1
        )
    }
}
