import Foundation
import PDFKit

public struct PDFMetadataInfo: Sendable, Codable, Hashable {
    public var title: String?
    public var author: String?
    public var subject: String?
    public var keywords: [String]
    public var creator: String?
    public var producer: String?
    public var creationDate: Date?
    public var modificationDate: Date?
    public var pageCount: Int
    public var majorVersion: Int
    public var minorVersion: Int
    public var isEncrypted: Bool
    public var isLocked: Bool
    public var allowsPrinting: Bool
    public var allowsCopying: Bool
    public var pageSizeSummary: String
    public var hasText: Bool

    public init(
        title: String? = nil,
        author: String? = nil,
        subject: String? = nil,
        keywords: [String] = [],
        creator: String? = nil,
        producer: String? = nil,
        creationDate: Date? = nil,
        modificationDate: Date? = nil,
        pageCount: Int = 0,
        majorVersion: Int = 1,
        minorVersion: Int = 7,
        isEncrypted: Bool = false,
        isLocked: Bool = false,
        allowsPrinting: Bool = true,
        allowsCopying: Bool = true,
        pageSizeSummary: String = "",
        hasText: Bool = false
    ) {
        self.title = title
        self.author = author
        self.subject = subject
        self.keywords = keywords
        self.creator = creator
        self.producer = producer
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.pageCount = pageCount
        self.majorVersion = majorVersion
        self.minorVersion = minorVersion
        self.isEncrypted = isEncrypted
        self.isLocked = isLocked
        self.allowsPrinting = allowsPrinting
        self.allowsCopying = allowsCopying
        self.pageSizeSummary = pageSizeSummary
        self.hasText = hasText
    }
}
