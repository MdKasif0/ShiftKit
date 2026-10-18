import Foundation
import CryptoKit
import UniformTypeIdentifiers

public struct FileInspectionSummary: Sendable, Codable, Hashable {
    public let fileSize: Int64
    public let formattedSize: String
    public let mimeType: String
    public let uti: String
    public let sha256: String
    public let isExecutable: Bool

    public init(
        fileSize: Int64,
        formattedSize: String,
        mimeType: String,
        uti: String,
        sha256: String,
        isExecutable: Bool
    ) {
        self.fileSize = fileSize
        self.formattedSize = formattedSize
        self.mimeType = mimeType
        self.uti = uti
        self.sha256 = sha256
        self.isExecutable = isExecutable
    }
}

public enum DeveloperUtilities {

    // MARK: - SHA-256 Hash

    /// Calculates SHA-256 hash using CryptoKit in streaming 64KB blocks.
    public static func calculateSHA256(for fileURL: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }

        var hasher = SHA256()
        let bufferSize = 64 * 1024

        while true {
            let chunk = handle.readData(ofLength: bufferSize)
            if chunk.isEmpty { break }
            hasher.update(data: chunk)
        }

        let digest = hasher.finalize()
        return digest.map { byte in String(format: "%02x", byte) }.joined()
    }

    /// Calculates SHA-256 hash for raw in-memory data.
    public static func calculateSHA256(for data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { byte in String(format: "%02x", byte) }.joined()
    }

    // MARK: - File Size & MIME Inspection

    public static func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    public static func inspectFile(at url: URL) throws -> FileInspectionSummary {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let size = (attributes[.size] as? Int64) ?? 0
        let formattedSize = formatFileSize(size)

        let ext = url.pathExtension.lowercased()
        let utType = UTType(filenameExtension: ext) ?? .data
        let utiString = utType.identifier
        let mimeType = utType.preferredMIMEType ?? (OutputFormat.find(byExtension: ext)?.mimeType ?? "application/octet-stream")

        let sha256 = (try? calculateSHA256(for: url)) ?? "Unavailable"
        let isExecutable = FileManager.default.isExecutableFile(atPath: url.path)

        return FileInspectionSummary(
            fileSize: size,
            formattedSize: formattedSize,
            mimeType: mimeType,
            uti: utiString,
            sha256: sha256,
            isExecutable: isExecutable
        )
    }

    // MARK: - Safe Archive Operations (Path Traversal / Zip Slip Protection)

    /// Compresses a file or directory into a ZIP archive safely using Apple ditto.
    @discardableResult
    public static func createZip(
        sourceURL: URL,
        destinationZipURL: URL
    ) throws -> URL {
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw ShiftKitError.conversionFailed(reason: "Source item does not exist at \(sourceURL.path).")
        }

        if FileManager.default.fileExists(atPath: destinationZipURL.path) {
            try FileManager.default.removeItem(at: destinationZipURL)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = [
            "-c", "-k",
            "--sequesterRsrc",
            "--keepParent",
            sourceURL.path,
            destinationZipURL.path
        ]

        let errPipe = Pipe()
        process.standardError = errPipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw ShiftKitError.conversionFailed(reason: "ditto zip creation failed: \(err)")
        }

        guard FileManager.default.fileExists(atPath: destinationZipURL.path) else {
            throw ShiftKitError.conversionFailed(reason: "ZIP archive was not generated.")
        }

        return destinationZipURL
    }

    /// Safely extracts an archive (ZIP, TAR, GZ) with strict Zip Slip / path traversal protection.
    @discardableResult
    public static func extractArchiveSafely(
        archiveURL: URL,
        destinationDirectory: URL
    ) throws -> URL {
        guard FileManager.default.fileExists(atPath: archiveURL.path) else {
            throw ShiftKitError.conversionFailed(reason: "Archive does not exist at \(archiveURL.path).")
        }

        let ext = archiveURL.pathExtension.lowercased()

        // 1. Audit archive contents for directory traversal before extraction
        try auditArchiveSafety(archiveURL: archiveURL, formatExtension: ext)

        // 2. Prepare destination directory
        try FileManager.default.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
        let canonicalDestination = destinationDirectory.resolvingSymlinksInPath()

        // 3. Extract based on format
        let process = Process()
        let errPipe = Pipe()
        process.standardError = errPipe

        if ext == "zip" {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            process.arguments = [
                "-x", "-k",
                archiveURL.path,
                destinationDirectory.path
            ]
        } else if ext == "tar" || ext == "gz" || ext == "tgz" {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
            process.arguments = [
                "-xf", archiveURL.path,
                "-C", destinationDirectory.path
            ]
        } else {
            throw ShiftKitError.conversionFailed(reason: "Unsupported archive format: .\(ext)")
        }

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw ShiftKitError.conversionFailed(reason: "Extraction failed: \(err)")
        }

        // 4. Post-extraction traversal verification
        try auditExtractedDirectory(canonicalDestination: canonicalDestination)

        return destinationDirectory
    }

    /// Audits the archive entries for path traversal patterns.
    public static func auditArchiveSafety(archiveURL: URL, formatExtension: String) throws {
        let process = Process()
        let outPipe = Pipe()
        process.standardOutput = outPipe

        if formatExtension == "zip" {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/zipinfo")
            process.arguments = ["-1", archiveURL.path]
        } else {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
            process.arguments = ["-tf", archiveURL.path]
        }

        try process.run()
        process.waitUntilExit()

        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return }

        let lines = output.components(separatedBy: .newlines)
        let maxAllowedEntries = 10_000
        guard lines.count <= maxAllowedEntries else {
            throw ShiftKitError.conversionFailed(
                reason: "Security Alert: Archive exceeds maximum entry count limit (\(lines.count) > \(maxAllowedEntries)). Extraction blocked to protect system resources."
            )
        }

        for line in lines {
            let entry = line.trimmingCharacters(in: .whitespaces)
            guard !entry.isEmpty else { continue }

            let components = entry.components(separatedBy: CharacterSet(charactersIn: "/\\"))
            if entry.hasPrefix("/") || entry.hasPrefix("\\") || components.contains("..") {
                throw ShiftKitError.conversionFailed(
                    reason: "Security Alert: Malicious archive entry '\(entry)' contains directory traversal sequences. Extraction blocked."
                )
            }
        }
    }

    /// Verifies that all items inside extracted folder stay within bounds.
    private static func auditExtractedDirectory(canonicalDestination: URL) throws {
        let base = canonicalDestination.path
        guard let enumerator = FileManager.default.enumerator(at: canonicalDestination, includingPropertiesForKeys: nil) else {
            return
        }

        for case let itemURL as URL in enumerator {
            let canonicalItem = itemURL.resolvingSymlinksInPath()
            if !canonicalItem.path.hasPrefix(base) {
                try? FileManager.default.removeItem(at: canonicalDestination)
                throw ShiftKitError.conversionFailed(
                    reason: "Security Alert: Extracted item \(canonicalItem.path) escaped target boundary \(base). Target cleaned."
                )
            }
        }
    }

    // MARK: - JSON Formatting & Validation

    public static func formatJSON(jsonString: String, pretty: Bool = true, sortedKeys: Bool = true) throws -> String {
        guard let data = jsonString.data(using: .utf8) else {
            throw ShiftKitError.conversionFailed(reason: "Invalid UTF-8 data for JSON formatting.")
        }

        let jsonObject: Any
        do {
            jsonObject = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        } catch {
            throw ShiftKitError.conversionFailed(reason: "JSON Syntax Error: \(error.localizedDescription)")
        }

        var options: JSONSerialization.WritingOptions = []
        if pretty { options.insert(.prettyPrinted) }
        if sortedKeys { options.insert(.sortedKeys) }

        let formattedData = try JSONSerialization.data(withJSONObject: jsonObject, options: options)
        guard let result = String(data: formattedData, encoding: .utf8) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to encode formatted JSON string.")
        }
        return result
    }

    public static func minifyJSON(jsonString: String) throws -> String {
        return try formatJSON(jsonString: jsonString, pretty: false, sortedKeys: false)
    }

    // MARK: - JSON <-> YAML Conversion

    public static func jsonToYAML(jsonString: String) throws -> String {
        guard let data = jsonString.data(using: .utf8) else {
            throw ShiftKitError.conversionFailed(reason: "Invalid UTF-8 string for YAML conversion.")
        }

        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        var yamlOutput = ""
        serializeToYAML(value: jsonObject, indentLevel: 0, output: &yamlOutput)
        return yamlOutput
    }

    private static func serializeToYAML(value: Any, indentLevel: Int, output: inout String) {
        let indent = String(repeating: "  ", count: indentLevel)

        if let dict = value as? [String: Any] {
            let sortedKeys = dict.keys.sorted()
            for key in sortedKeys {
                guard let val = dict[key] else { continue }
                if let childDict = val as? [String: Any] {
                    output += "\(indent)\(key):\n"
                    serializeToYAML(value: childDict, indentLevel: indentLevel + 1, output: &output)
                } else if let childArr = val as? [Any] {
                    output += "\(indent)\(key):\n"
                    serializeToYAML(value: childArr, indentLevel: indentLevel + 1, output: &output)
                } else {
                    output += "\(indent)\(key): \(formatYAMLPrimitive(val))\n"
                }
            }
        } else if let array = value as? [Any] {
            for item in array {
                if let itemDict = item as? [String: Any] {
                    output += "\(indent)- \n"
                    serializeToYAML(value: itemDict, indentLevel: indentLevel + 1, output: &output)
                } else if let itemArr = item as? [Any] {
                    output += "\(indent)- \n"
                    serializeToYAML(value: itemArr, indentLevel: indentLevel + 1, output: &output)
                } else {
                    output += "\(indent)- \(formatYAMLPrimitive(item))\n"
                }
            }
        } else {
            output += "\(indent)\(formatYAMLPrimitive(value))\n"
        }
    }

    private static func formatYAMLPrimitive(_ val: Any) -> String {
        if let str = val as? String {
            if str.contains(":") || str.contains("#") || str.contains("\n") || str.contains("\"") {
                let escaped = str.replacingOccurrences(of: "\"", with: "\\\"")
                return "\"" + escaped + "\""
            }
            return str
        } else if let num = val as? NSNumber {
            if CFGetTypeID(num) == CFBooleanGetTypeID() {
                return num.boolValue ? "true" : "false"
            }
            return num.stringValue
        } else {
            return "\(val)"
        }
    }

    public static func yamlToJSON(yamlString: String) throws -> String {
        let lines = yamlString.components(separatedBy: .newlines)
        var dict: [String: Any] = [:]

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.starts(with: "#") else { continue }

            if let colonIdx = trimmed.firstIndex(of: ":") {
                let key = String(trimmed[..<colonIdx]).trimmingCharacters(in: .whitespaces)
                let valueStr = String(trimmed[trimmed.index(after: colonIdx)...]).trimmingCharacters(in: .whitespaces)

                if valueStr.lowercased() == "true" {
                    dict[key] = true
                } else if valueStr.lowercased() == "false" {
                    dict[key] = false
                } else if let intVal = Int(valueStr) {
                    dict[key] = intVal
                } else if let dblVal = Double(valueStr) {
                    dict[key] = dblVal
                } else {
                    let unquoted = valueStr.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                    dict[key] = unquoted
                }
            }
        }

        let data = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
        guard let jsonResult = String(data: data, encoding: .utf8) else {
            throw ShiftKitError.conversionFailed(reason: "Failed to encode JSON from YAML.")
        }
        return jsonResult
    }

    // MARK: - Base64 Encoding & Decoding

    public static func encodeBase64(fileURL: URL, lineLength: Int? = 76) throws -> String {
        let data = try Data(contentsOf: fileURL)
        let base64 = data.base64EncodedString()

        guard let wrap = lineLength, wrap > 0 else {
            return base64
        }

        var wrapped = ""
        var idx = base64.startIndex
        while idx < base64.endIndex {
            let nextIdx = base64.index(idx, offsetBy: wrap, limitedBy: base64.endIndex) ?? base64.endIndex
            wrapped += String(base64[idx..<nextIdx]) + "\n"
            idx = nextIdx
        }
        return wrapped.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func decodeBase64(base64String: String, outputURL: URL) throws {
        let cleaned = base64String.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
        guard let data = Data(base64Encoded: cleaned) else {
            throw ShiftKitError.conversionFailed(reason: "Invalid Base64 payload provided.")
        }
        try data.write(to: outputURL)
    }
}
