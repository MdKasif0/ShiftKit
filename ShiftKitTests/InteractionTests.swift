import XCTest
import AppKit
@testable import ShiftKit

final class InteractionTests: XCTestCase {
    func testPermissionManagerExplainingStrings() {
        let manager = InteractionPermissionManager.shared
        XCTAssertFalse(manager.permissionExplanationTitle.isEmpty)
        XCTAssertFalse(manager.permissionExplanationDescription.isEmpty)
        XCTAssertTrue(manager.isPermissionOptional)
    }

    func testModifierKeyTrackerBasics() {
        let tracker = ModifierKeyTracker.shared
        XCTAssertNotNil(tracker)
        tracker.startTracking()
        // Ensure properties can be read synchronously without blocking
        _ = tracker.isShiftPressed
        _ = tracker.isOptionPressed
        _ = tracker.isCommandPressed
    }

    @MainActor
    func testDragSessionCoordinatorStateTransitions() {
        let coordinator = DragSessionCoordinator.shared
        XCTAssertNotNil(coordinator)

        let initial = coordinator.currentState
        XCTAssertEqual(initial, .idle)

        // Simulate Shift+drag trigger
        let testLocation = CGPoint(x: 500, y: 500)
        coordinator.handleShiftDragAt(testLocation)

        XCTAssertEqual(coordinator.currentState, .dropDestinationActive(location: testLocation))

        // Dismiss floating target
        RadialMenuWindowController.shared.dismiss()
    }

    func testDropDestinationHitTesting() {
        let destination = DropDestinationView(frame: NSRect(x: 0, y: 0, width: 360, height: 360))
        XCTAssertNotNil(destination)
        XCTAssertTrue(destination.registeredDraggedTypes.contains(.fileURL))
        XCTAssertTrue(destination.registeredDraggedTypes.contains(.URL))
        XCTAssertFalse(destination.registeredDraggedTypes.isEmpty)
    }
}
