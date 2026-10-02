import UIKit
import XCTest
@testable import BLTNBoard

@MainActor
final class BulletinViewControllerLayoutTests: XCTestCase {

    private typealias Fixture = (window: UIWindow, parent: UIViewController,
                                controller: BulletinViewController, manager: BLTNItemManager)

    func testRegularWidthCardFitsNarrowContainerAndExpandsWithIt() {
        let fixture = makeFixture(size: CGSize(width: 320, height: 700),
                                  horizontalSizeClass: .regular, contentHeight: 180)
        defer { removeFixture(fixture) }

        XCTAssertEqual(fixture.controller.traitCollection.horizontalSizeClass, .regular)
        assertCardIsWithinSafeArea(fixture.controller)
        let narrowWidth = fixture.controller.contentView.bounds.width
        XCTAssertGreaterThan(narrowWidth, 0)
        XCTAssertLessThan(narrowWidth, fixture.controller.view.bounds.width)

        layout(fixture, size: CGSize(width: 760, height: 700))

        assertCardIsWithinSafeArea(fixture.controller)
        XCTAssertGreaterThan(fixture.controller.contentView.bounds.width, narrowWidth)
        let safeFrame = fixture.controller.view.bounds.inset(by: fixture.controller.view.safeAreaInsets)
        XCTAssertEqual(fixture.controller.contentView.frame.midX, safeFrame.midX, accuracy: 0.5)
    }

    func testShortContainerScrollsLongContentAndExpansionShowsItAll() {
        let fixture = makeFixture(size: CGSize(width: 620, height: 260),
                                  horizontalSizeClass: .regular, contentHeight: 620)
        defer { removeFixture(fixture) }
        let scrollView = fixture.controller.contentScrollView

        assertCardIsWithinSafeArea(fixture.controller)
        XCTAssertTrue(scrollView.isScrollEnabled)
        XCTAssertGreaterThan(scrollView.contentSize.height, scrollView.bounds.height)
        let bottomOffset = scrollView.contentSize.height - scrollView.bounds.height
            + scrollView.adjustedContentInset.bottom
        scrollView.setContentOffset(CGPoint(x: 0, y: bottomOffset), animated: false)
        XCTAssertGreaterThan(scrollView.contentOffset.y, 0)

        layout(fixture, size: CGSize(width: 620, height: 980))

        assertCardIsWithinSafeArea(fixture.controller)
        XCTAssertFalse(scrollView.isScrollEnabled)
        let fullContentHeight = scrollView.contentSize.height
            + scrollView.adjustedContentInset.top + scrollView.adjustedContentInset.bottom
        XCTAssertGreaterThanOrEqual(scrollView.bounds.height + 1, fullContentHeight)
        XCTAssertLessThanOrEqual(scrollView.contentOffset.y, -scrollView.adjustedContentInset.top + 1)
    }

    func testCompactCardKeepsDesignSpacingWhenSafeAreaChanges() {
        let fixture = makeFixture(size: CGSize(width: 390, height: 700),
                                  horizontalSizeClass: .compact, contentHeight: 160)
        defer { removeFixture(fixture) }
        let controller = fixture.controller
        let originalSafeFrame = controller.view.bounds.inset(by: controller.view.safeAreaInsets)
        let originalCardFrame = controller.contentView.frame
        let originalBottomGap = originalSafeFrame.maxY - originalCardFrame.maxY
        XCTAssertEqual(originalBottomGap, fixture.manager.edgeSpacing.rawValue, accuracy: 0.5)

        controller.additionalSafeAreaInsets = UIEdgeInsets(top: 11, left: 29, bottom: 36, right: 7)
        layout(fixture)

        let safeFrame = controller.view.bounds.inset(by: controller.view.safeAreaInsets)
        let cardFrame = controller.contentView.frame
        assertCardIsWithinSafeArea(controller)
        XCTAssertLessThan(safeFrame.maxY, originalSafeFrame.maxY)
        XCTAssertLessThan(cardFrame.maxY, originalCardFrame.maxY)
        XCTAssertEqual(safeFrame.maxY - cardFrame.maxY, originalBottomGap, accuracy: 0.5)
        XCTAssertEqual(cardFrame.minX - safeFrame.minX, fixture.manager.edgeSpacing.rawValue, accuracy: 0.5)
        XCTAssertEqual(safeFrame.maxX - cardFrame.maxX, fixture.manager.edgeSpacing.rawValue, accuracy: 0.5)
    }

    func testNoEdgeSpacingKeepsSquareCardWithinBoundsAfterResize() {
        let fixture = makeFixture(size: CGSize(width: 390, height: 700),
                                  horizontalSizeClass: .compact, contentHeight: 160,
                                  requestedRadius: 28, edgeSpacing: .none)
        defer { removeFixture(fixture) }
        let initialWidth = fixture.controller.contentView.bounds.width
        assertCardIsWithinSafeArea(fixture.controller)
        XCTAssertEqual(fixture.controller.contentView.cornerRadius, 0)

        layout(fixture, size: CGSize(width: 620, height: 400))

        assertCardIsWithinSafeArea(fixture.controller)
        XCTAssertGreaterThan(fixture.controller.contentView.bounds.width, initialWidth)
        XCTAssertEqual(fixture.controller.contentView.cornerRadius, 0)
    }

    func testHiddenHomeIndicatorExtendsSurfaceAndKeepsContentAboveBottomInset() {
        let fixture = makeFixture(size: CGSize(width: 390, height: 700),
                                  horizontalSizeClass: .compact, contentHeight: 160,
                                  hidesHomeIndicator: true)
        defer { removeFixture(fixture) }
        let controller = fixture.controller

        for bottomInset: CGFloat in [36, 60] {
            controller.additionalSafeAreaInsets.bottom = bottomInset
            layout(fixture)

            let safeFrame = controller.view.bounds.inset(by: controller.view.safeAreaInsets)
            let cardFrame = controller.contentView.frame
            let stackFrame = controller.contentStackView.convert(controller.contentStackView.bounds,
                                                                  to: controller.view)
            XCTAssertGreaterThan(controller.view.safeAreaInsets.bottom, 0)
            XCTAssertGreaterThan(cardFrame.maxY, safeFrame.maxY)
            XCTAssertTrue(controller.view.bounds.insetBy(dx: -0.5, dy: -0.5).contains(cardFrame))
            XCTAssertLessThanOrEqual(stackFrame.maxY, safeFrame.maxY + 0.5)
            XCTAssertFalse(controller.contentScrollView.isScrollEnabled)
        }
    }

    func testDefaultCornerRadiusDoesNotDependOnSafeAreaInsets() {
        assertCornerRadiusSurvivesSafeAreaChange(requestedRadius: nil)
    }

    func testExplicitCornerRadiusDoesNotDependOnSafeAreaInsets() {
        assertCornerRadiusSurvivesSafeAreaChange(requestedRadius: 28)
    }

    func testLoadedViewInteractionsDoNotRetainController() {
        let item = BLTNItem()
        item.shouldRespondToKeyboardChanges = false
        let manager = BLTNItemManager(rootItem: item)
        var controller: BulletinViewController? = BulletinViewController()
        controller?.manager = manager
        controller?.loadBackgroundView()
        controller?.loadViewIfNeeded()
        let retainedView: UIView = controller!.view
        weak let releasedController = controller

        if #available(iOS 27.1, *) {
            XCTAssertFalse(retainedView.interactions.isEmpty)
        }
        controller = nil

        // Keep the view and its interactions alive to expose any controller capture cycle.
        withExtendedLifetime((manager, retainedView)) {
            XCTAssertNil(releasedController)
        }
    }

    func testKeyboardResponsiveCardKeepsItsNormalLayoutWhileKeyboardIsHidden() {
        for sizeClass in [UIUserInterfaceSizeClass.compact, .regular] {
            let fixture = makeFixture(size: CGSize(width: 390, height: 700),
                                      horizontalSizeClass: sizeClass, contentHeight: 160,
                                      respondsToKeyboard: true)
            defer { removeFixture(fixture) }
            let originalFrame = fixture.controller.contentView.frame
            assertCardIsWithinSafeArea(fixture.controller)

            fixture.manager.currentItem.shouldRespondToKeyboardChanges = false
            fixture.controller.refreshLayout()
            layout(fixture)

            let optedOutFrame = fixture.controller.contentView.frame
            XCTAssertEqual(optedOutFrame.minY, originalFrame.minY, accuracy: 0.5)
            XCTAssertEqual(optedOutFrame.height, originalFrame.height, accuracy: 0.5)
            assertCardIsWithinSafeArea(fixture.controller)
        }
    }

    private func makeFixture(size: CGSize, horizontalSizeClass: UIUserInterfaceSizeClass,
                             contentHeight: CGFloat, requestedRadius: NSNumber? = nil,
                             edgeSpacing: BLTNSpacing = .custom(18),
                             hidesHomeIndicator: Bool = false,
                             respondsToKeyboard: Bool = false) -> Fixture {
        let item = BLTNItem()
        item.shouldRespondToKeyboardChanges = respondsToKeyboard
        let manager = BLTNItemManager(rootItem: item)
        manager.edgeSpacing = edgeSpacing
        manager.cardCornerRadius = requestedRadius
        manager.hidesHomeIndicator = hidesHomeIndicator

        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        let parent = UIViewController()
        window.rootViewController = parent
        window.isHidden = false
        parent.loadViewIfNeeded()

        let controller = BulletinViewController()
        controller.manager = manager
        controller.loadBackgroundView()
        parent.addChild(controller)
        if #available(iOS 17.0, *) {
            controller.traitOverrides.horizontalSizeClass = horizontalSizeClass
            controller.traitOverrides.verticalSizeClass = .regular
        } else {
            let traits = UITraitCollection(traitsFrom: [
                UITraitCollection(horizontalSizeClass: horizontalSizeClass),
                UITraitCollection(verticalSizeClass: .regular),
            ])
            parent.setOverrideTraitCollection(traits, forChild: controller)
        }
        controller.loadViewIfNeeded()
        controller.view.frame = parent.view.bounds
        parent.view.addSubview(controller.view)
        controller.didMove(toParent: parent)

        // A fixed content height makes the resize checks independent of font and locale.
        let content = UILabel()
        content.text = "Bulletin content"
        content.translatesAutoresizingMaskIntoConstraints = false
        content.heightAnchor.constraint(equalToConstant: contentHeight).isActive = true
        controller.contentStackView.addArrangedSubview(content)

        let fixture = (window, parent, controller, manager)
        controller.moveIntoPlace()
        layout(fixture, size: size)
        XCTAssertNotNil(controller.view.window)
        return fixture
    }

    private func layout(_ fixture: Fixture, size: CGSize? = nil) {
        UIView.performWithoutAnimation {
            if let size {
                fixture.window.frame = CGRect(origin: .zero, size: size)
                fixture.parent.view.frame = fixture.window.bounds
                fixture.controller.view.frame = fixture.parent.view.bounds
            }
            // Insets and scroll content geometry can each request a follow-up layout pass.
            for _ in 0..<3 {
                fixture.window.layoutIfNeeded()
                fixture.parent.view.layoutIfNeeded()
                fixture.controller.view.setNeedsLayout()
                fixture.controller.view.layoutIfNeeded()
            }
        }
    }

    private func removeFixture(_ fixture: Fixture) {
        fixture.controller.willMove(toParent: nil)
        fixture.controller.view.removeFromSuperview()
        fixture.controller.removeFromParent()
        fixture.window.isHidden = true
        fixture.window.rootViewController = nil
    }

    private func assertCardIsWithinSafeArea(_ controller: BulletinViewController,
                                           file: StaticString = #filePath, line: UInt = #line) {
        let safeFrame = controller.view.bounds.inset(by: controller.view.safeAreaInsets)
        let cardFrame = controller.contentView.frame
        XCTAssertGreaterThan(cardFrame.width, 0, file: file, line: line)
        XCTAssertGreaterThan(cardFrame.height, 0, file: file, line: line)
        XCTAssertGreaterThanOrEqual(cardFrame.minX + 0.5, safeFrame.minX, file: file, line: line)
        XCTAssertGreaterThanOrEqual(cardFrame.minY + 0.5, safeFrame.minY, file: file, line: line)
        XCTAssertLessThanOrEqual(cardFrame.maxX, safeFrame.maxX + 0.5, file: file, line: line)
        XCTAssertLessThanOrEqual(cardFrame.maxY, safeFrame.maxY + 0.5, file: file, line: line)
    }

    private func assertCornerRadiusSurvivesSafeAreaChange(requestedRadius: NSNumber?,
                                                        file: StaticString = #filePath, line: UInt = #line) {
        let fixture = makeFixture(size: CGSize(width: 390, height: 700),
                                  horizontalSizeClass: .compact, contentHeight: 160,
                                  requestedRadius: requestedRadius)
        defer { removeFixture(fixture) }
        let controller = fixture.controller
        let initialRadius = controller.contentView.cornerRadius
        let initialBottomInset = controller.view.safeAreaInsets.bottom
        XCTAssertGreaterThan(initialRadius, 0, file: file, line: line)
        if let requestedRadius {
            XCTAssertEqual(initialRadius, CGFloat(requestedRadius.doubleValue), accuracy: 0.5,
                           file: file, line: line)
        }

        controller.additionalSafeAreaInsets = UIEdgeInsets(top: 17, left: 9, bottom: 36, right: 23)
        layout(fixture)

        XCTAssertGreaterThan(controller.view.safeAreaInsets.bottom, initialBottomInset, file: file, line: line)
        XCTAssertEqual(controller.contentView.cornerRadius, initialRadius, accuracy: 0.5, file: file, line: line)
        assertCardIsWithinSafeArea(controller, file: file, line: line)
    }
}
