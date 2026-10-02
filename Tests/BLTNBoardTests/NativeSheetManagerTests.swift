import UIKit
import XCTest
@testable import BLTNBoard

@MainActor
final class NativeSheetManagerTests: XCTestCase {

    func testNativeRequestUsesCustomPresenterOnOlderReleases() async throws {
        let (window, parent) = try makePresenter()
        defer { removePresenter(window) }
        let manager = BLTNItemManager(rootItem: NativeSheetTrackingItem())
        XCTAssertEqual(manager.presentationStyle, .custom)
        manager.presentationStyle = .nativeSheet
        await show(manager, above: parent)

        if #available(iOS 26.0, *) {
            XCTAssertTrue(manager.presentationController is NativeBulletinViewController)
        } else {
            XCTAssertTrue(manager.presentationController is BulletinViewController)
        }
        await dismiss(manager)
    }

    func testLoadingKeepsHeightControlsAndValuesAndRestoresDismissal() async throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Native sheets require iOS 26") }
        let (window, parent) = try makePresenter()
        defer { removePresenter(window) }
        let item = NativeSheetTrackingItem()
        let manager = nativeManager(item)
        await show(manager, above: parent)
        let controller = try XCTUnwrap(manager.presentationController as? NativeBulletinViewController)
        layout(controller)
        let sheet = try XCTUnwrap(controller.sheetPresentationController)
        let field = try XCTUnwrap(item.textField)
        field.text = "Saved name"
        let height = controller.measuredContentHeight
        XCTAssertTrue(controller.presentationControllerShouldDismiss(sheet))

        manager.displayActivityIndicator()
        layout(controller)
        XCTAssertEqual(controller.measuredContentHeight, height, accuracy: 0.5)
        XCTAssertTrue(controller.isModalInPresentation)
        XCTAssertFalse(controller.presentationControllerShouldDismiss(sheet))
        XCTAssertFalse(controller.accessibilityPerformEscape())

        manager.hideActivityIndicator()
        layout(controller)
        XCTAssertTrue(item.textField === field)
        XCTAssertEqual(field.text, "Saved name")
        XCTAssertEqual(item.makeViewsCount, 1)
        XCTAssertEqual(item.setUpCount, 1)
        XCTAssertEqual(controller.measuredContentHeight, height, accuracy: 0.5)
        XCTAssertFalse(controller.isModalInPresentation)
        XCTAssertTrue(controller.presentationControllerShouldDismiss(sheet))
        await dismiss(manager)
    }

    func testPushPopRestoresEachItemsHeightAndDismissalPolicy() async throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Native sheets require iOS 26") }
        let (window, parent) = try makePresenter()
        defer { removePresenter(window) }
        let root = NativeSheetTrackingItem(contentHeight: 100)
        let first = NativeSheetTrackingItem(contentHeight: 240)
        first.isDismissable = false
        let second = NativeSheetTrackingItem(contentHeight: 480)
        second.shouldStartWithActivityIndicator = true
        let manager = nativeManager(root)
        await show(manager, above: parent)
        let controller = try XCTUnwrap(manager.presentationController as? NativeBulletinViewController)
        let sheet = try XCTUnwrap(controller.sheetPresentationController)
        layout(controller)
        let rootHeight = controller.measuredContentHeight

        manager.push(item: first)
        layout(controller)
        let firstHeight = controller.measuredContentHeight
        XCTAssertGreaterThan(firstHeight, rootHeight)
        XCTAssertFalse(controller.presentationControllerShouldDismiss(sheet))
        XCTAssertEqual(root.tearDownCount, 1)

        manager.push(item: second)
        layout(controller)
        XCTAssertFalse(controller.presentationControllerShouldDismiss(sheet))
        manager.hideActivityIndicator()
        layout(controller)
        XCTAssertGreaterThan(controller.measuredContentHeight, firstHeight)
        XCTAssertTrue(controller.presentationControllerShouldDismiss(sheet))
        XCTAssertEqual(second.makeViewsCount, 1)

        manager.popItem()
        layout(controller)
        XCTAssertTrue(manager.currentItem === first)
        XCTAssertEqual(controller.measuredContentHeight, firstHeight, accuracy: 0.5)
        XCTAssertFalse(controller.presentationControllerShouldDismiss(sheet))
        XCTAssertEqual(first.setUpCount, 2)
        XCTAssertEqual(first.displayCount, 2)
        XCTAssertEqual(second.tearDownCount, 1)

        manager.popToRootItem()
        layout(controller)
        XCTAssertTrue(manager.currentItem === root)
        XCTAssertEqual(controller.measuredContentHeight, rootHeight, accuracy: 0.5)
        XCTAssertTrue(controller.presentationControllerShouldDismiss(sheet))
        XCTAssertEqual(root.setUpCount, 2)
        XCTAssertEqual(root.displayCount, 2)
        await dismiss(manager)
    }

    func testExplicitDismissalAndReleaseCleanUpTheActiveItemOnce() async throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Native sheets require iOS 26") }
        let (window, parent) = try makePresenter()
        defer { removePresenter(window) }
        let item = NativeSheetTrackingItem()
        var manager: BLTNItemManager? = nativeManager(item)
        await show(manager!, above: parent)
        weak let releasedController = manager?.presentationController
        await dismiss(manager!)
        XCTAssertNil(manager?.presentationController)
        XCTAssertNil(item.manager)
        XCTAssertEqual(item.tearDownCount, 1)
        XCTAssertEqual(item.dismissCount, 1)
        manager = nil
        await Task.yield()
        XCTAssertNil(releasedController)
        XCTAssertEqual(item.tearDownCount, 1)
        XCTAssertEqual(item.dismissCount, 1)
    }

    func testNativeDismissalIgnoresDuplicateDelegateCallbacksAndCanReopen() async throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Native sheets require iOS 26") }
        let (window, parent) = try makePresenter()
        defer { removePresenter(window) }
        let item = NativeSheetTrackingItem()
        let manager = nativeManager(item)
        await show(manager, above: parent)
        let controller = try XCTUnwrap(manager.presentationController as? NativeBulletinViewController)
        let sheet = try XCTUnwrap(controller.sheetPresentationController)
        await dismissController(controller)
        // UIKit delivers didDismiss after its own transition. A late duplicate must be harmless.
        controller.presentationControllerDidDismiss(sheet)
        controller.presentationControllerDidDismiss(sheet)
        XCTAssertNil(manager.presentationController)
        XCTAssertNil(item.manager)
        XCTAssertEqual(item.tearDownCount, 1)
        XCTAssertEqual(item.dismissCount, 1)

        await show(manager, above: parent)
        XCTAssertTrue(manager.isShowingBulletin)
        XCTAssertEqual(item.setUpCount, 2)
        XCTAssertEqual(item.displayCount, 2)
        // A callback from the previous sheet cannot dismiss the new display episode.
        controller.presentationControllerDidDismiss(sheet)
        XCTAssertTrue(manager.isShowingBulletin)
        await dismiss(manager)
        XCTAssertEqual(item.tearDownCount, 2)
        XCTAssertEqual(item.dismissCount, 2)
    }

    func testOverlayPresentationKeepsTheBulletinAndItemActive() async throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Native sheets require iOS 26") }
        let (window, parent) = try makePresenter()
        defer { removePresenter(window) }
        let item = NativeSheetTrackingItem()
        let manager = nativeManager(item)
        await show(manager, above: parent)
        let originalController = manager.presentationController
        let overlay = UIViewController()
        overlay.modalPresentationStyle = .overFullScreen
        let presented = expectation(description: "Overlay presented")
        manager.present(overlay, animated: false) { presented.fulfill() }
        await fulfillment(of: [presented], timeout: 3)
        await dismissController(overlay)

        XCTAssertTrue(manager.presentationController === originalController)
        XCTAssertTrue(manager.isShowingBulletin)
        XCTAssertTrue(item.manager === manager)
        XCTAssertEqual(item.tearDownCount, 0)
        XCTAssertEqual(item.dismissCount, 0)
        await dismiss(manager)
    }

    func testDisplayCallbackCanPushTheNextNativeItem() async throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Native sheets require iOS 26") }
        let (window, parent) = try makePresenter()
        defer { removePresenter(window) }
        let root = NativeSheetTrackingItem()
        let next = NativeSheetTrackingItem(contentHeight: 300)
        root.presentationHandler = { item in item.manager?.push(item: next) }
        let manager = nativeManager(root)
        await show(manager, above: parent)
        XCTAssertTrue(manager.currentItem === next)
        XCTAssertTrue(next.manager === manager)
        XCTAssertEqual(root.tearDownCount, 1)
        XCTAssertEqual(next.setUpCount, 1)
        XCTAssertEqual(next.displayCount, 1)
        await dismiss(manager)
    }

    func testDisablingSwipeStillAllowsExplicitDismissal() async throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Native sheets require iOS 26") }
        let (window, parent) = try makePresenter()
        defer { removePresenter(window) }
        let item = NativeSheetTrackingItem()
        let manager = nativeManager(item)
        manager.allowsSwipeInteraction = false
        await show(manager, above: parent)
        let controller = try XCTUnwrap(manager.presentationController as? NativeBulletinViewController)
        let sheet = try XCTUnwrap(controller.sheetPresentationController)
        XCTAssertTrue(controller.isModalInPresentation)
        XCTAssertFalse(controller.presentationControllerShouldDismiss(sheet))
        await dismiss(manager)
        XCTAssertEqual(item.dismissCount, 1)
    }

    func testNativeScenePresentationKeepsTheExistingWindow() async throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Native sheets require iOS 26") }
        let (window, parent) = try makePresenter()
        defer { removePresenter(window) }
        let scene = try XCTUnwrap(window.windowScene)
        let existingWindows = Set(scene.windows.map(ObjectIdentifier.init))
        let manager = nativeManager(NativeSheetTrackingItem())
        let presented = expectation(description: "Scene bulletin presented")
        manager.showBulletin(in: scene, animated: false) { presented.fulfill() }
        await fulfillment(of: [presented], timeout: 3)

        XCTAssertTrue(manager.presentationController?.presentingViewController === parent)
        XCTAssertTrue(scene.windows.allSatisfy { existingWindows.contains(ObjectIdentifier($0)) })
        XCTAssertTrue(window.isKeyWindow)
        await dismiss(manager)
    }

    func testLongNativePageHasAVisibleViewportAfterDismissalAndReopen() async throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Native sheets require iOS 26") }
        let (window, parent) = try makePresenter()
        defer { removePresenter(window) }
        let intro = nativeManager(NativeSheetTrackingItem())
        await show(intro, above: parent)
        await dismiss(intro)

        for _ in 0..<2 {
            let page = BLTNPageItem(title: "Long guide")
            page.descriptionText = String(repeating: "Keep every paragraph and the final action reachable.\n\n", count: 40)
            page.actionButtonTitle = "Done"
            let manager = nativeManager(page)
            await show(manager, above: parent)
            let controller = try XCTUnwrap(manager.presentationController as? NativeBulletinViewController)
            // Check the presented viewport before any test-driven layout pass.
            XCTAssertGreaterThan(controller.view.bounds.height, 100)
            XCTAssertGreaterThan(controller.contentScrollView.bounds.height, 100)
            XCTAssertGreaterThan(controller.contentScrollView.contentSize.height,
                                 controller.contentScrollView.bounds.height)
            await dismiss(manager)
        }
    }

    func testDismissalDuringCustomPushDoesNotDisplayAStaleItem() async throws {
        let (window, parent) = try makePresenter()
        defer { removePresenter(window) }
        let manager = BLTNItemManager(rootItem: NativeSheetTrackingItem())
        await show(manager, above: parent)
        let next = NativeSheetTrackingItem()
        let staleDisplay = expectation(description: "Dismissed item must not display")
        staleDisplay.isInverted = true
        next.presentationHandler = { _ in staleDisplay.fulfill() }

        manager.push(item: next)
        await dismiss(manager)
        await fulfillment(of: [staleDisplay], timeout: 1)
        XCTAssertNil(manager.presentationController)
        XCTAssertEqual(next.tearDownCount, 1)
        XCTAssertEqual(next.displayCount, 0)
    }

    private func nativeManager(_ item: BLTNItem) -> BLTNItemManager {
        let manager = BLTNItemManager(rootItem: item)
        manager.presentationStyle = .nativeSheet
        return manager
    }

    private func makePresenter() throws -> (UIWindow, UIViewController) {
        // A real UIKit presentation needs a scene. This lookup belongs only to the test host.
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first else {
            throw XCTSkip("The test host has no window scene for a UIKit presentation")
        }
        let window = UIWindow(windowScene: scene)
        let parent = UIViewController()
        window.rootViewController = parent
        window.makeKeyAndVisible()
        parent.loadViewIfNeeded()
        window.layoutIfNeeded()
        return (window, parent)
    }

    private func removePresenter(_ window: UIWindow) {
        window.isHidden = true
        window.rootViewController = nil
    }

    private func show(_ manager: BLTNItemManager, above parent: UIViewController) async {
        let presented = expectation(description: "Bulletin presented")
        manager.showBulletin(above: parent, animated: false) { presented.fulfill() }
        await fulfillment(of: [presented], timeout: 3)
    }

    private func dismiss(_ manager: BLTNItemManager) async {
        let dismissed = expectation(description: "Bulletin dismissed")
        manager.currentItem.dismissalHandler = { _ in dismissed.fulfill() }
        manager.dismissBulletin(animated: false)
        await fulfillment(of: [dismissed], timeout: 3)
    }

    private func dismissController(_ controller: UIViewController) async {
        let dismissed = expectation(description: "Controller dismissed")
        controller.dismiss(animated: false) { dismissed.fulfill() }
        await fulfillment(of: [dismissed], timeout: 3)
    }

    private func layout(_ controller: UIViewController) {
        UIView.performWithoutAnimation {
            for _ in 0..<3 {
                controller.view.setNeedsLayout()
                controller.view.layoutIfNeeded()
            }
        }
    }
}
