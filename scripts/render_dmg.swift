import Cocoa
import WebKit

guard CommandLine.arguments.count >= 3 else {
    print("Usage: swift render_dmg.swift <input.html> <output.png> [width] [height]")
    exit(1)
}

let htmlPath = CommandLine.arguments[1]
let outputPath = CommandLine.arguments[2]
let width: CGFloat = CommandLine.arguments.count > 3 ? CGFloat(Double(CommandLine.arguments[3]) ?? 1320) : 1320
let height: CGFloat = CommandLine.arguments.count > 4 ? CGFloat(Double(CommandLine.arguments[4]) ?? 840) : 840

let app = NSApplication.shared
class RenderDelegate: NSObject, WKNavigationDelegate {
    let webView: WKWebView
    let outputPath: String
    
    init(webView: WKWebView, outputPath: String) {
        self.webView = webView
        self.outputPath = outputPath
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Give time for layout/rendering
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let config = WKSnapshotConfiguration()
            config.snapshotWidth = NSNumber(value: Double(self.webView.frame.width))
            self.webView.takeSnapshot(with: config) { image, error in
                if let error = error {
                    print("Error snapshot: \(error)")
                    exit(1)
                }
                guard let image = image,
                      let tiffData = image.tiffRepresentation,
                      let bitmap = NSBitmapImageRep(data: tiffData),
                      let pngData = bitmap.representation(using: .png, properties: [:]) else {
                    print("Error converting to PNG")
                    exit(1)
                }
                do {
                    try pngData.write(to: URL(fileURLWithPath: self.outputPath))
                    print("Successfully saved image to \(self.outputPath)")
                    exit(0)
                } catch {
                    print("Error writing: \(error)")
                    exit(1)
                }
            }
        }
    }
}

let frame = CGRect(x: 0, y: 0, width: width, height: height)
let webView = WKWebView(frame: frame)
let delegate = RenderDelegate(webView: webView, outputPath: outputPath)
webView.navigationDelegate = delegate

let htmlUrl = URL(fileURLWithPath: htmlPath)
webView.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent())

// Run runloop
RunLoop.main.run(until: Date(timeIntervalSinceNow: 5))
exit(0)
