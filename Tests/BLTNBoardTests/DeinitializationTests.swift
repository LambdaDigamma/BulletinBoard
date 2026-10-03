import UIKit
import XCTest
@testable import BLTNBoard

@MainActor
final class DeinitializationTests: XCTestCase {
    func testSynchronousAnimationReleasePreservesTaskLocalScope() async {
        await withCheckedContinuation { continuation in
            // UIKit releases animation blocks from a main queue callback, outside a Swift task.
            DispatchQueue.main.async {
                withUnsafeCurrentTask { XCTAssertNil($0) }
                DeinitializationTaskLocal.$marker.withValue(17) {
                    var phase: AnimationPhase? = AnimationPhase(relativeDuration: 1, curve: .linear)
                    weak var capturedView: UIView?
                    do {
                        let view = UIView()
                        capturedView = view
                        phase?.block = { view.alpha = 0.5 }
                    }
                    weak let releasedPhase = phase
                    phase = nil
                    XCTAssertNil(releasedPhase)
                    XCTAssertNil(capturedView)
                    XCTAssertEqual(DeinitializationTaskLocal.marker, 17)
                }
                XCTAssertEqual(DeinitializationTaskLocal.marker, 0)
                continuation.resume()
            }
        }
    }

    func testSynchronousChainReleaseReleasesPendingAnimations() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                withUnsafeCurrentTask { XCTAssertNil($0) }
                DeinitializationTaskLocal.$marker.withValue(17) {
                    var chain: AnimationChain? = AnimationChain(duration: 0.1)
                    weak var releasedPhase: AnimationPhase?
                    do {
                        let phase = AnimationPhase(relativeDuration: 1, curve: .linear)
                        releasedPhase = phase
                        chain?.add(phase)
                    }
                    weak let releasedChain = chain
                    chain = nil
                    XCTAssertNil(releasedChain)
                    XCTAssertNil(releasedPhase)
                    XCTAssertEqual(DeinitializationTaskLocal.marker, 17)
                }
                XCTAssertEqual(DeinitializationTaskLocal.marker, 0)
                continuation.resume()
            }
        }
    }

    func testSynchronousControllerReleasePreservesTaskLocalScope() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                withUnsafeCurrentTask { XCTAssertNil($0) }
                DeinitializationTaskLocal.$marker.withValue(17) {
                    var controller: NativeBulletinViewController? = NativeBulletinViewController()
                    weak let releasedController = controller
                    controller = nil
                    XCTAssertNil(releasedController)
                    XCTAssertEqual(DeinitializationTaskLocal.marker, 17)
                }
                XCTAssertEqual(DeinitializationTaskLocal.marker, 0)
                continuation.resume()
            }
        }
    }

    func testSynchronousManagerReleaseTearsDownItemsOnMainActor() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                withUnsafeCurrentTask { XCTAssertNil($0) }
                DeinitializationTaskLocal.$marker.withValue(17) {
                    var teardownOrder: [Int] = []
                    let root = TearDownTrackingItem { teardownOrder.append(1) }
                    let next = TearDownTrackingItem { teardownOrder.append(2) }
                    root.next = next
                    var manager: BLTNItemManager? = BLTNItemManager(rootItem: root)
                    root.manager = manager
                    next.manager = manager
                    weak let releasedManager = manager
                    manager = nil
                    XCTAssertNil(releasedManager)
                    XCTAssertEqual(teardownOrder, [1, 2])
                    XCTAssertNil(root.next)
                    XCTAssertNil(root.manager)
                    XCTAssertNil(next.manager)
                    XCTAssertEqual(DeinitializationTaskLocal.marker, 17)
                }
                XCTAssertEqual(DeinitializationTaskLocal.marker, 0)
                continuation.resume()
            }
        }
    }

    func testBackgroundManagerReleaseTearsDownItemsOnMainActor() async {
        let teardown = expectation(description: "Items torn down on MainActor")
        let release = expectation(description: "Manager released away from MainActor")
        let root = TearDownTrackingItem {
            XCTAssertEqual(DeinitializationTaskLocal.marker, 17)
            teardown.fulfill()
        }
        // Deliberately test final release by a non-actor owner. The public manager is Sendable.
        let task = Task.detached {
            var manager: BLTNItemManager? = await MainActor.run { BLTNItemManager(rootItem: root) }
            weak let releasedManager = manager
            DeinitializationTaskLocal.$marker.withValue(17) {
                manager = nil
            }
            XCTAssertNil(releasedManager)
            release.fulfill()
        }
        await fulfillment(of: [teardown, release], timeout: 5)
        await task.value
    }

    func testAnimationCompletionReleasesChainAndPhases() async {
        let completed = expectation(description: "Animation chain completed")
        let view = UIView()
        var chain: AnimationChain? = AnimationChain(duration: 0.05)
        weak let releasedChain = chain
        var releasedPhases: [() -> AnimationPhase?] = []
        var completedPhases = 0
        for alpha in [0.5, 1.0] {
            let phase = AnimationPhase(relativeDuration: 0.5, curve: .linear)
            phase.block = { view.alpha = alpha }
            phase.completionHandler = { completedPhases += 1 }
            releasedPhases.append { [weak phase] in phase }
            chain?.add(phase)
        }
        chain?.completionHandler = { completed.fulfill() }
        chain?.start()
        chain = nil
        await fulfillment(of: [completed], timeout: 5)
        // Let UIKit return from its completion callback before checking ARC ownership.
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                XCTAssertEqual(completedPhases, 2)
                XCTAssertEqual(view.alpha, 1)
                XCTAssertNil(releasedChain)
                for phase in releasedPhases { XCTAssertNil(phase()) }
                continuation.resume()
            }
        }
    }
}
