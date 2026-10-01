import XCTest
@testable import BLTNBoard

@MainActor
final class TearDownTrackingItem: BLTNPageItem {
    private let onTearDown: @MainActor () -> Void

    init(onTearDown: @escaping @MainActor () -> Void) {
        self.onTearDown = onTearDown
        super.init(title: "Test bulletin")
    }

    nonisolated deinit {}

    override func tearDown() {
        MainActor.assertIsolated()
        XCTAssertTrue(Thread.isMainThread)
        super.tearDown()
        onTearDown()
    }
}
