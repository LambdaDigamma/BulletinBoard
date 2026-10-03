import UIKit
import XCTest
@testable import BLTNBoard

@MainActor
final class NativeSheetManagerTests: XCTestCase {

    func testDefaultPresenterIsNativeOnEverySupportedRelease() async throws {
        let (window, parent) = try makePresenter()
        defer { removePresenter(window) }
        let manager = BLTNItemManager(rootItem: NativeSheetTrackingItem())
        await show(manager, above: parent)

        XCTAssertTrue(manager.presentationController is NativeBulletinViewController)
        await dismiss(manager)
    }

    func testLoadingKeepsHeightControlsAndValuesAndRestoresDismissal() async throws {
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

    func testStartupLoadingIndicatorAdaptsToAppearanceAndKeepsExplicitColor() async throws {
        let (window, parent) = try makePresenter()
        defer { removePresenter(window) }
        let item = NativeSheetTrackingItem()
        item.shouldStartWithActivityIndicator = true
        let manager = nativeManager(item)
        await show(manager, above: parent)
        let controller = try XCTUnwrap(manager.presentationController as? NativeBulletinViewController)
        let color = try XCTUnwrap(controller.activityIndicator.color)

        for style in [UIUserInterfaceStyle.light, .dark] {
            controller.traitOverrides.userInterfaceStyle = style
            layout(controller)
            var brightness: CGFloat = 0
            var alpha: CGFloat = 0
            XCTAssertTrue(color.resolvedColor(with: controller.traitCollection).getWhite(&brightness, alpha: &alpha))
            XCTAssertEqual(alpha, 1)
            if style == .dark {
                XCTAssertGreaterThan(brightness, 0.5)
            } else {
                XCTAssertLessThan(brightness, 0.5)
            }
        }

        manager.displayActivityIndicator(color: .systemOrange)
        XCTAssertEqual(controller.activityIndicator.color, .systemOrange)
        await dismiss(manager)
    }

    func testPushPopRestoresEachItemsHeightAndDismissalPolicy() async throws {
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

        await changePage(to: first) { manager.push(item: first) }
        layout(controller)
        let firstHeight = controller.measuredContentHeight
        XCTAssertGreaterThan(firstHeight, rootHeight)
        XCTAssertFalse(controller.presentationControllerShouldDismiss(sheet))
        XCTAssertEqual(root.tearDownCount, 1)

        await changePage(to: second) { manager.push(item: second) }
        layout(controller)
        XCTAssertFalse(controller.presentationControllerShouldDismiss(sheet))
        manager.hideActivityIndicator()
        layout(controller)
        XCTAssertGreaterThan(controller.measuredContentHeight, firstHeight)
        XCTAssertTrue(controller.presentationControllerShouldDismiss(sheet))
        XCTAssertEqual(second.makeViewsCount, 1)

        await changePage(to: first) { manager.popItem() }
        layout(controller)
        XCTAssertTrue(manager.currentItem === first)
        XCTAssertEqual(controller.measuredContentHeight, firstHeight, accuracy: 0.5)
        XCTAssertFalse(controller.presentationControllerShouldDismiss(sheet))
        XCTAssertEqual(first.setUpCount, 2)
        XCTAssertEqual(first.displayCount, 2)
        XCTAssertEqual(second.tearDownCount, 1)

        await changePage(to: root) { manager.popToRootItem() }
        layout(controller)
        XCTAssertTrue(manager.currentItem === root)
        XCTAssertEqual(controller.measuredContentHeight, rootHeight, accuracy: 0.5)
        XCTAssertTrue(controller.presentationControllerShouldDismiss(sheet))
        XCTAssertEqual(root.setUpCount, 2)
        XCTAssertEqual(root.displayCount, 2)
        await dismiss(manager)
    }

    func testExplicitDismissalAndReleaseCleanUpTheActiveItemOnce() async throws {
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
        let (window, parent) = try makePresenter()
        defer { removePresenter(window) }
        let root = NativeSheetTrackingItem()
        let next = NativeSheetTrackingItem(contentHeight: 300)
        root.presentationHandler = { item in item.manager?.push(item: next) }
        let manager = nativeManager(root)
        await show(manager, above: parent)
        await waitForDisplay(next)
        XCTAssertTrue(manager.currentItem === next)
        XCTAssertTrue(next.manager === manager)
        XCTAssertEqual(root.tearDownCount, 1)
        XCTAssertEqual(next.setUpCount, 1)
        XCTAssertEqual(next.displayCount, 1)
        await dismiss(manager)
    }

    func testDisablingSwipeStillAllowsExplicitDismissal() async throws {
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

    func testDismissalDuringNativePushDoesNotDisplayAStaleItem() async throws {
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

    func testRapidPushCancelsTheOutgoingPageAndRestoresInput() async throws {
        let (window, parent) = try makePresenter()
        defer { removePresenter(window) }
        let manager = nativeManager(NativeSheetTrackingItem())
        await show(manager, above: parent)
        let controller = try XCTUnwrap(manager.presentationController as? NativeBulletinViewController)
        let first = NativeSheetTrackingItem(contentHeight: 420)
        let last = NativeSheetTrackingItem(contentHeight: 100)
        let originalHeight = controller.measuredContentHeight
        manager.push(item: first)
        XCTAssertTrue(controller.isTransitioningItem)
        XCTAssertFalse(controller.contentContainer.isUserInteractionEnabled)
        await changePage(to: last) {
            manager.push(item: last)
            layout(controller)
            XCTAssertEqual(controller.measuredContentHeight, originalHeight, accuracy: 0.5)
        }
        XCTAssertEqual(first.displayCount, 0)
        XCTAssertEqual(first.tearDownCount, 1)
        XCTAssertEqual(last.willDisplayCount, 1)
        XCTAssertEqual(last.displayCount, 1)
        XCTAssertFalse(controller.isTransitioningItem)
        XCTAssertTrue(controller.contentContainer.isUserInteractionEnabled)
        XCTAssertEqual(controller.view.subviews.count, 1, "No outgoing snapshot remains")
        await dismiss(manager)
    }

    func testLoadingDuringPageFadePreservesViewsAndCompletesDisplayOnce() async throws {
        let (window, parent) = try makePresenter()
        defer { removePresenter(window) }
        let manager = nativeManager(NativeSheetTrackingItem())
        await show(manager, above: parent)
        let controller = try XCTUnwrap(manager.presentationController as? NativeBulletinViewController)
        for delay in [0, 200] {
            let next = NativeSheetTrackingItem(contentHeight: 300)
            manager.push(item: next)
            if delay > 0 { try await Task.sleep(for: .milliseconds(delay)) }
            let field = try XCTUnwrap(next.textField)
            field.text = "Keep this edit"
            let height = controller.measuredContentHeight
            manager.displayActivityIndicator()
            layout(controller)
            XCTAssertEqual(controller.measuredContentHeight, height, accuracy: 0.5)
            XCTAssertEqual(controller.activityIndicator.alpha, 1)
            XCTAssertFalse(controller.isTransitioningItem)
            XCTAssertEqual(controller.view.subviews.count, 1)
            XCTAssertTrue(controller.isModalInPresentation)
            await changePage(to: next) { manager.hideActivityIndicator() }
            XCTAssertTrue(next.textField === field)
            XCTAssertEqual(field.text, "Keep this edit")
            XCTAssertEqual(next.makeViewsCount, 1)
            XCTAssertEqual(next.willDisplayCount, 1)
            XCTAssertEqual(next.displayCount, 1)
            XCTAssertFalse(controller.isModalInPresentation)
            XCTAssertEqual(controller.contentStackView.alpha, 1)
        }
        await dismiss(manager)
    }

    func testPageHeightAnimatesThroughIntermediateSizesInBothDirections() async throws {
        guard !UIAccessibility.isReduceMotionEnabled else { throw XCTSkip("Reduce Motion disables size animation") }
        let (window, parent) = try makePresenter()
        defer { removePresenter(window) }
        let short = NativeSheetTrackingItem(contentHeight: 80)
        let tall = NativeSheetTrackingItem(contentHeight: 400)
        let manager = nativeManager(short)
        await show(manager, above: parent)
        let controller = try XCTUnwrap(manager.presentationController as? NativeBulletinViewController)

        for item in [tall, short] {
            let start = controller.view.bounds.height
            manager.push(item: item)
            var heights: [CGFloat] = []
            var opacities: [Float] = []
            for _ in 0..<45 {
                try await Task.sleep(for: .milliseconds(20))
                heights.append(controller.view.layer.presentation()?.bounds.height ?? controller.view.bounds.height)
                opacities.append(controller.contentStackView.layer.presentation()?.opacity ?? controller.contentStackView.layer.opacity)
            }
            let end = controller.view.bounds.height
            XCTAssertGreaterThan(abs(end - start), 100)
            XCTAssertTrue(heights.contains { $0 > min(start, end) + 2 && $0 < max(start, end) - 2 },
                          "The sheet must pass through intermediate heights: \(heights)")
            XCTAssertTrue(opacities.contains { $0 > 0.02 && $0 < 0.98 },
                          "New content must fade through intermediate opacity: \(opacities)")
            XCTAssertFalse(controller.isTransitioningItem)
            XCTAssertEqual(controller.contentStackView.alpha, 1)
        }
        await dismiss(manager)
    }

    func testWillDisplayCanReplaceThePageWithoutCompletingTheOldFade() async throws {
        let (window, parent) = try makePresenter()
        defer { removePresenter(window) }
        let manager = nativeManager(NativeSheetTrackingItem())
        await show(manager, above: parent)
        let first = NativeSheetTrackingItem(contentHeight: 400)
        let last = NativeSheetTrackingItem(contentHeight: 100)
        first.willDisplayHandler = { [weak manager] in manager?.push(item: last) }
        manager.push(item: first)
        await waitForDisplay(last)
        XCTAssertTrue(manager.currentItem === last)
        XCTAssertEqual(first.willDisplayCount, 1)
        XCTAssertEqual(first.displayCount, 0)
        XCTAssertEqual(first.tearDownCount, 1)
        XCTAssertEqual(last.displayCount, 1)
        await dismiss(manager)
    }

    func testDisabledAnimationsApplyThePageAndCallbacksImmediately() async throws {
        let (window, parent) = try makePresenter()
        defer { removePresenter(window) }
        let manager = nativeManager(NativeSheetTrackingItem())
        await show(manager, above: parent)
        let next = NativeSheetTrackingItem(contentHeight: 400)
        UIView.performWithoutAnimation { manager.push(item: next) }
        let controller = try XCTUnwrap(manager.presentationController as? NativeBulletinViewController)
        XCTAssertFalse(controller.isTransitioningItem)
        XCTAssertEqual(next.willDisplayCount, 1)
        XCTAssertEqual(next.displayCount, 1)
        XCTAssertTrue(controller.contentContainer.isUserInteractionEnabled)
        XCTAssertEqual(controller.contentStackView.alpha, 1)
        await dismiss(manager)
    }

    func testShortPageBottomMarginIsCompactAndSafeAreaAnchorDoesNotAddSpace() async throws {
        let (window, parent) = try makePresenter()
        defer { removePresenter(window) }
        let page = BLTNPageItem(title: "Customize Feed")
        page.descriptionText = "Choose whether to share your location."
        page.actionButtonTitle = "Send location data"
        page.alternativeButtonTitle = "No thanks"
        page.isDismissable = false
        let manager = nativeManager(page)
        await show(manager, above: parent)
        let controller = try XCTUnwrap(manager.presentationController as? NativeBulletinViewController)
        let button = try XCTUnwrap(page.alternativeButton)
        layout(controller)
        let originalFrame = button.convert(button.bounds, to: controller.view)
        let safeFrame = controller.view.safeAreaLayoutGuide.layoutFrame
        XCTAssertLessThanOrEqual(originalFrame.maxY, safeFrame.maxY + 1)
        if controller.view.safeAreaInsets.bottom >= 12 {
            XCTAssertEqual(safeFrame.maxY, originalFrame.maxY, accuracy: 1)
        } else {
            XCTAssertEqual(controller.view.bounds.maxY - originalFrame.maxY, 12, accuracy: 1)
        }

        let scroll = controller.contentScrollView
        let container = controller.contentContainer
        let bottom = try XCTUnwrap(container.constraints.first {
            ($0.firstItem as? UIView) === scroll && $0.firstAttribute == .bottom
                && ($0.secondItem as? UIView) === container && $0.secondAttribute == .bottom
        })
        // Compare a frame inside the safe area with automatic scroll-content insets.
        bottom.isActive = false
        let safeBottom = scroll.bottomAnchor.constraint(equalTo: container.safeAreaLayoutGuide.bottomAnchor)
        safeBottom.isActive = true
        layout(controller)
        let guideFrame = button.convert(button.bounds, to: controller.view)
        XCTAssertEqual(guideFrame.maxY, originalFrame.maxY, accuracy: 1)
        XCTAssertEqual(scroll.frame.maxY, safeFrame.maxY, accuracy: 1)
        XCTAssertEqual(scroll.adjustedContentInset.bottom, 0, accuracy: 1)
        XCTAssertLessThanOrEqual(guideFrame.maxY, controller.view.safeAreaLayoutGuide.layoutFrame.maxY + 1)
        await dismiss(manager)
    }

    func testFloatingSheetRetainsMinimumBottomClearance() async throws {
        let (window, parent) = try makePresenter()
        defer { removePresenter(window) }
        guard parent.traitCollection.horizontalSizeClass == .regular else {
            throw XCTSkip("This check needs a regular-width floating sheet")
        }
        let page = BLTNPageItem(title: "Floating bulletin")
        page.descriptionText = "Keep the final control clear of the rounded sheet edge."
        page.actionButtonTitle = "Done"
        page.requiresCloseButton = false
        let manager = nativeManager(page)
        await show(manager, above: parent)
        let controller = try XCTUnwrap(manager.presentationController as? NativeBulletinViewController)
        let button = try XCTUnwrap(page.actionButton)
        layout(controller)
        XCTAssertEqual(controller.view.safeAreaInsets.bottom, 0)
        XCTAssertEqual(controller.contentScrollView.adjustedContentInset.bottom, 0)
        let frame = button.convert(button.bounds, to: controller.view)
        XCTAssertEqual(controller.view.bounds.maxY - frame.maxY, 12, accuracy: 1)
        let hit = controller.view.hitTest(CGPoint(x: frame.midX, y: frame.midY), with: nil)
        XCTAssertTrue(hit?.isDescendant(of: button) == true)
        await dismiss(manager)
    }

    private func changePage(to item: BLTNItem, change: () -> Void) async {
        let displayed = expectation(description: "Page displayed")
        item.presentationHandler = { _ in displayed.fulfill() }
        change()
        await fulfillment(of: [displayed], timeout: 3)
        item.presentationHandler = nil
    }

    private func waitForDisplay(_ item: NativeSheetTrackingItem) async {
        if item.displayCount > 0 { return }
        let displayed = expectation(description: "Page displayed")
        item.presentationHandler = { _ in displayed.fulfill() }
        await fulfillment(of: [displayed], timeout: 3)
        item.presentationHandler = nil
    }

    private func nativeManager(_ item: BLTNItem) -> BLTNItemManager {
        let manager = BLTNItemManager(rootItem: item)
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
