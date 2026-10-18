import Foundation
import Observation
import Sparkle

@Observable
@MainActor
public final class UpdateManager {
    public static let shared = UpdateManager()

    public private(set) var state: UpdateState = .idle
    public private(set) var lastCheckDate: Date? = nil
    public private(set) var lastError: String? = nil
    public private(set) var isReady: Bool = false

    private var updaterController: SPUStandardUpdaterController?
    private var updaterDelegate: SparkleUpdaterDelegate?
    private var isInitialized: Bool = false

    public init(startImmediately: Bool = true) {
        if startImmediately {
            initializeIfNeeded()
        }
    }

    public func initializeIfNeeded() {
        guard !isInitialized else { return }
        isInitialized = true

        let delegate = SparkleUpdaterDelegate(manager: self)
        self.updaterDelegate = delegate

        // SPUStandardUpdaterController starts Sparkle background checking if startingUpdater is true
        let controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: delegate,
            userDriverDelegate: nil
        )
        self.updaterController = controller
        self.isReady = true
        self.state = .idle
    }

    // MARK: - Version & Metadata Accessors

    public var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    public var currentBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    public var feedURLString: String? {
        Bundle.main.infoDictionary?["SUFeedURL"] as? String
    }

    public var publicEDKey: String? {
        Bundle.main.infoDictionary?["SUPublicEDKey"] as? String
    }

    public var isConfigured: Bool {
        guard let feed = feedURLString, !feed.isEmpty,
              let key = publicEDKey, !key.isEmpty else {
            return false
        }
        return true
    }

    // MARK: - Updater Control & Preferences

    public var canCheckForUpdates: Bool {
        updaterController?.updater.canCheckForUpdates ?? false
    }

    public var automaticallyChecksForUpdates: Bool {
        get {
            updaterController?.updater.automaticallyChecksForUpdates ?? true
        }
        set {
            updaterController?.updater.automaticallyChecksForUpdates = newValue
        }
    }

    public var automaticallyDownloadsUpdates: Bool {
        get {
            updaterController?.updater.automaticallyDownloadsUpdates ?? false
        }
        set {
            updaterController?.updater.automaticallyDownloadsUpdates = newValue
        }
    }

    public var updateCheckInterval: TimeInterval {
        get {
            updaterController?.updater.updateCheckInterval ?? 86400
        }
        set {
            updaterController?.updater.updateCheckInterval = newValue
        }
    }

    // MARK: - Actions

    public func checkForUpdates() {
        guard isReady, let controller = updaterController else {
            self.state = .error("Updater is not initialized")
            return
        }

        self.lastError = nil
        self.state = .checking

        // Trigger manual check via standard user driver (presents standard Sparkle modal dialogs)
        controller.checkForUpdates(nil)
    }

    public func checkForUpdatesInBackground() {
        guard isReady, let controller = updaterController else { return }
        controller.updater.checkForUpdatesInBackground()
    }

    public func resetState() {
        self.state = .idle
        self.lastError = nil
    }

    // MARK: - Internal Delegate Callbacks

    internal func didFinishLoadingAppcast() {
        self.lastCheckDate = Date()
    }

    internal func didFindValidUpdate(version: String) {
        self.lastCheckDate = Date()
        self.state = .updateAvailable(version: version)
    }

    internal func didNotFindUpdate(error: (any Error)?) {
        self.lastCheckDate = Date()
        if let error {
            let desc = error.localizedDescription
            self.lastError = desc
            self.state = .error(desc)
        } else {
            self.state = .upToDate
        }
    }

    internal func didAbortWithError(_ error: any Error) {
        let desc = error.localizedDescription
        self.lastError = desc
        self.state = .error(desc)
    }

    internal func willRelaunchApplication() {
        // Prepare application before restart
    }
}
