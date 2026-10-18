import Foundation
import Sparkle

public final class SparkleUpdaterDelegate: NSObject, SPUUpdaterDelegate, @unchecked Sendable {
    private weak var manager: UpdateManager?

    public init(manager: UpdateManager) {
        self.manager = manager
        super.init()
    }

    public func updater(_ updater: SPUUpdater, didFinishLoading appcast: SUAppcast) {
        Task { @MainActor [weak self] in
            self?.manager?.didFinishLoadingAppcast()
        }
    }

    public func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        let versionString = item.displayVersionString
        Task { @MainActor [weak self] in
            self?.manager?.didFindValidUpdate(version: versionString)
        }
    }

    public func updaterDidNotFindUpdate(_ updater: SPUUpdater, error: (any Error)?) {
        Task { @MainActor [weak self] in
            self?.manager?.didNotFindUpdate(error: error)
        }
    }

    public func updater(_ updater: SPUUpdater, didAbortWithError error: any Error) {
        Task { @MainActor [weak self] in
            self?.manager?.didAbortWithError(error)
        }
    }

    public func updaterWillRelaunchApplication(_ updater: SPUUpdater) {
        Task { @MainActor [weak self] in
            self?.manager?.willRelaunchApplication()
        }
    }
}
