import XCTest
import CoreGraphics
import SwiftUI
@testable import ShiftKit

final class MenuLayoutEngineTests: XCTestCase {
    private var engine: MenuLayoutEngine!
    private var geometry: MenuGeometry!
    private let bounds = CGSize(width: 360, height: 360)

    override func setUp() {
        super.setUp()
        engine = MenuLayoutEngine.shared
        geometry = MenuGeometry(
            innerRadius: 58,
            outerRadius: 158,
            centerHubRadius: 52,
            segmentCount: 8,
            startAngleOffset: -90.0
        )
    }

    func testAngleRangeCalculations() {
        // Segment 0 (top, starting at -90 deg)
        let seg0 = engine.angleRange(for: 0, geometry: geometry)
        XCTAssertEqual(seg0.start.degrees, -90.0, accuracy: 0.001)
        XCTAssertEqual(seg0.end.degrees, -45.0, accuracy: 0.001)
        XCTAssertEqual(seg0.mid.degrees, -67.5, accuracy: 0.001)

        // Segment 2 (right quadrant, from 0 to 45 deg)
        let seg2 = engine.angleRange(for: 2, geometry: geometry)
        XCTAssertEqual(seg2.start.degrees, 0.0, accuracy: 0.001)
        XCTAssertEqual(seg2.end.degrees, 45.0, accuracy: 0.001)
        XCTAssertEqual(seg2.mid.degrees, 22.5, accuracy: 0.001)

        // Segment 7 (last segment, from 225 to 270 / -135 to -90 deg)
        let seg7 = engine.angleRange(for: 7, geometry: geometry)
        XCTAssertEqual(seg7.start.degrees, 225.0, accuracy: 0.001)
        XCTAssertEqual(seg7.end.degrees, 270.0, accuracy: 0.001)
    }

    func testHitDetectionCenterHub() {
        let center = CGPoint(x: 180, y: 180)
        XCTAssertEqual(engine.hitTest(point: center, in: bounds, geometry: geometry), .centerHub)

        let nearCenter = CGPoint(x: 180 + 30, y: 180)
        XCTAssertEqual(engine.hitTest(point: nearCenter, in: bounds, geometry: geometry), .centerHub)
    }

    func testHitDetectionSegments() {
        let center = CGPoint(x: 180, y: 180)

        // Segment 0: Top right slice (mid angle -67.5 deg)
        let seg0Pt = engine.pointOnCircle(radius: 100, angle: Angle(degrees: -67.5), center: center)
        XCTAssertEqual(engine.hitTest(point: seg0Pt, in: bounds, geometry: geometry), .segment(index: 0))

        // Segment 2: East slice (mid angle 22.5 deg)
        let seg2Pt = engine.pointOnCircle(radius: 100, angle: Angle(degrees: 22.5), center: center)
        XCTAssertEqual(engine.hitTest(point: seg2Pt, in: bounds, geometry: geometry), .segment(index: 2))

        // Segment 4: South slice (mid angle 112.5 deg)
        let seg4Pt = engine.pointOnCircle(radius: 100, angle: Angle(degrees: 112.5), center: center)
        XCTAssertEqual(engine.hitTest(point: seg4Pt, in: bounds, geometry: geometry), .segment(index: 4))

        // Segment 6: West slice (mid angle 202.5 deg)
        let seg6Pt = engine.pointOnCircle(radius: 100, angle: Angle(degrees: 202.5), center: center)
        XCTAssertEqual(engine.hitTest(point: seg6Pt, in: bounds, geometry: geometry), .segment(index: 6))
    }

    func testHitDetectionOutside() {
        // Far outside radius
        let farOutside = CGPoint(x: 350, y: 350)
        XCTAssertEqual(engine.hitTest(point: farOutside, in: bounds, geometry: geometry), .outside)

        // Dead zone between center hub (52) and inner radius (58)
        let deadZone = CGPoint(x: 180 + 55, y: 180)
        XCTAssertEqual(engine.hitTest(point: deadZone, in: bounds, geometry: geometry), .outside)
    }

    func testScreenClamping() {
        let fakeScreenFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let windowSize = CGSize(width: 360, height: 360)

        // Inside center
        let origin = engine.clampedWindowOrigin(
            targetCenter: CGPoint(x: 720, y: 450),
            windowSize: windowSize
        )
        XCTAssertEqual(origin.x, 720 - 180, accuracy: 20.0)
        XCTAssertEqual(origin.y, 450 - 180, accuracy: 20.0)

        // Off left edge
        let leftOrigin = engine.clampedWindowOrigin(
            targetCenter: CGPoint(x: -100, y: 450),
            windowSize: windowSize
        )
        XCTAssertGreaterThanOrEqual(leftOrigin.x, 0)
    }

    func testContextualSegmentsGeneration() {
        let registry = ConversionRegistry()

        // Images get "Crop" on segment 3
        let imgSegments = registry.segments(for: .image(.png))
        XCTAssertEqual(imgSegments.count, 8)
        XCTAssertEqual(imgSegments[0].title, "Convert")
        XCTAssertEqual(imgSegments[1].title, "Compress")
        XCTAssertEqual(imgSegments[2].title, "Crop")
        XCTAssertEqual(imgSegments[3].title, "Merge")
        XCTAssertEqual(imgSegments[4].title, "Edit")
        XCTAssertEqual(imgSegments[5].title, "Metadata")
        XCTAssertEqual(imgSegments[6].title, "Extract")
        XCTAssertEqual(imgSegments[7].title, "More")

        // Videos get "Trim" on segment 3
        let vidSegments = registry.segments(for: .video(.mp4))
        XCTAssertEqual(vidSegments.count, 8)
        XCTAssertEqual(vidSegments[2].title, "Trim")
        XCTAssertEqual(vidSegments[2].systemIcon, "scissors")
    }

    func testSearchableActionsCatalog() {
        let registry = ConversionRegistry()
        let webpResults = registry.searchableActions(for: .image(.png), query: "webp")
        XCTAssertFalse(webpResults.isEmpty)
        XCTAssertTrue(webpResults.contains(where: { $0.id == "img_to_webp" }))

        let emptyResults = registry.searchableActions(for: .image(.png), query: "nonexistentformat999")
        XCTAssertTrue(emptyResults.isEmpty)
    }
}
