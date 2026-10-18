import XCTest
import AppKit
@testable import ShiftKit

final class DesignSystemTests: XCTestCase {
    func testBrandColorValues() {
        // Verify warm ivory #FAF8F3
        let ivory = ShiftKitColors.NS.warmIvory
        XCTAssertEqual(Int(round(ivory.redComponent * 255)), 0xFA)
        XCTAssertEqual(Int(round(ivory.greenComponent * 255)), 0xF8)
        XCTAssertEqual(Int(round(ivory.blueComponent * 255)), 0xF3)

        // Verify deep olive #465343
        let olive = ShiftKitColors.NS.deepOlive
        XCTAssertEqual(Int(round(olive.redComponent * 255)), 0x46)
        XCTAssertEqual(Int(round(olive.greenComponent * 255)), 0x53)
        XCTAssertEqual(Int(round(olive.blueComponent * 255)), 0x43)

        // Verify soft terracotta #D98768
        let terracotta = ShiftKitColors.NS.softTerracotta
        XCTAssertEqual(Int(round(terracotta.redComponent * 255)), 0xD9)
        XCTAssertEqual(Int(round(terracotta.greenComponent * 255)), 0x87)
        XCTAssertEqual(Int(round(terracotta.blueComponent * 255)), 0x68)

        // Verify charcoal brown #34312D
        let charcoal = ShiftKitColors.NS.charcoalBrown
        XCTAssertEqual(Int(round(charcoal.redComponent * 255)), 0x34)
        XCTAssertEqual(Int(round(charcoal.greenComponent * 255)), 0x31)
        XCTAssertEqual(Int(round(charcoal.blueComponent * 255)), 0x2D)
    }

    func testForbiddenColorsConstraint() {
        // Verify no saturated purple or blue hues in brand colors
        let colors = [
            ShiftKitColors.NS.warmIvory,
            ShiftKitColors.NS.softCream,
            ShiftKitColors.NS.pureWhite,
            ShiftKitColors.NS.mutedSage,
            ShiftKitColors.NS.deepOlive,
            ShiftKitColors.NS.softTerracotta,
            ShiftKitColors.NS.warmPeach,
            ShiftKitColors.NS.sandBeige,
            ShiftKitColors.NS.charcoalBrown
        ]

        for color in colors {
            // Saturated blue has blue component much higher than red and green
            let r = color.redComponent
            let g = color.greenComponent
            let b = color.blueComponent

            // Ensure blue is not dominant over both red and green by significant margin
            XCTAssertFalse(b > 0.7 && b > (r + 0.2) && b > (g + 0.2), "Detected forbidden saturated blue color!")
        }
    }
}
