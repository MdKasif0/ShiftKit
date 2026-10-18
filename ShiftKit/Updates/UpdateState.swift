import Foundation

public enum UpdateState: Equatable, Sendable {
    case idle
    case checking
    case updateAvailable(version: String)
    case upToDate
    case error(String)

    public var statusDescription: String {
        switch self {
        case .idle:
            return "Ready to check for updates"
        case .checking:
            return "Checking for updates..."
        case .updateAvailable(let version):
            return "Update v\(version) is available"
        case .upToDate:
            return "ShiftKit is up to date"
        case .error(let message):
            return message
        }
    }
}
