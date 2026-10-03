import UIKit
import XCTest
@testable import BLTNBoard

@MainActor
final class NativeSheetLayoutTests: XCTestCase {

    func testCloseButtonKeepsAReachableHeaderAboveScrollingContentInBothDirections() throws {
        let text = UILabel()
        text.numberOfLines = 0
        text.text = String(repeating: "Long content must not scroll under Close. ", count: 40)
        let fixture = makeFixture(size: CGSize(width: 360, height: 320), content: [text])
        defer { removeFixture(fixture) }
        let controller = fixture.controller
        controller.updateCloseButton(isRequired: true)
        controller.additionalSafeAreaInsets = UIEdgeInsets(top: 12, left: 20, bottom: 0, right: 8)
        for direction in [UITraitEnvironmentLayoutDirection.leftToRight, .rightToLeft] {
            controller.traitOverrides.layoutDirection = direction
            layout(fixture)
            let frame = controller.closeButton.convert(controller.closeButton.bounds, to: controller.view)
            let safeFrame = controller.view.bounds.inset(by: controller.view.safeAreaInsets)
            XCTAssertEqual(frame.height, 44)
            XCTAssertEqual(frame.minY - safeFrame.minY, 16, accuracy: 0.5)
            if direction == .leftToRight {
                XCTAssertEqual(safeFrame.maxX, frame.maxX, accuracy: 0.5)
            } else {
                XCTAssertEqual(frame.minX, safeFrame.minX, accuracy: 0.5)
            }
            let scroll = controller.contentScrollView
            XCTAssertGreaterThanOrEqual(scroll.frame.minY, frame.maxY + 8)
            scroll.setContentOffset(CGPoint(x: 0, y: scroll.contentSize.height - scroll.bounds.height), animated: false)
            let x = direction == .leftToRight ? frame.maxX - 38 : frame.minX + 38
            let hit = controller.view.hitTest(CGPoint(x: x, y: frame.midY), with: nil)
            XCTAssertTrue(hit?.isDescendant(of: controller.closeButton) == true)
        }
        controller.updateCloseButton(isRequired: false)
        layout(fixture)
        XCTAssertFalse(controller.closeButton.isUserInteractionEnabled)
        XCTAssertTrue(controller.closeButton.accessibilityElementsHidden)
        XCTAssertEqual(controller.contentScrollView.frame.minY, 0, accuracy: 0.5)
    }

    private typealias Fixture = (window: UIWindow, parent: UIViewController,
                                controller: NativeBulletinViewController, manager: BLTNItemManager)

    func testWidthAndAsymmetricSafeAreaChangesRecomputeContentHeight() throws {
        let text = UILabel()
        text.numberOfLines = 0
        text.text = String(repeating: "Content must fit the current sheet width. ", count: 24)
        let fixture = makeFixture(size: CGSize(width: 620, height: 600), content: [text])
        defer { removeFixture(fixture) }
        let controller = fixture.controller
        let wideHeight = controller.measuredContentHeight

        layout(fixture, size: CGSize(width: 320, height: 600))
        let narrowHeight = controller.measuredContentHeight
        XCTAssertGreaterThan(narrowHeight, wideHeight)
        let originalWidth = controller.contentStackView.bounds.width

        controller.additionalSafeAreaInsets = UIEdgeInsets(top: 10, left: 32, bottom: 25, right: 8)
        layout(fixture)
        XCTAssertLessThan(controller.contentStackView.bounds.width, originalWidth)
        XCTAssertGreaterThan(controller.measuredContentHeight, narrowHeight)
        let frame = text.convert(text.bounds, to: controller.view)
        let safeFrame = controller.view.bounds.inset(by: controller.view.safeAreaInsets)
        XCTAssertGreaterThanOrEqual(frame.minX, safeFrame.minX)
        XCTAssertLessThanOrEqual(frame.maxX, safeFrame.maxX)
    }

    func testLongContentCanScrollItsFinalActionIntoViewAndReceiveATap() throws {
        let content = UIView()
        content.heightAnchor.constraint(equalToConstant: 900).isActive = true
        let action = UIButton(type: .system)
        action.setTitle("Done", for: .normal)
        action.heightAnchor.constraint(equalToConstant: 44).isActive = true
        let fixture = makeFixture(size: CGSize(width: 360, height: 260), content: [content, action])
        defer { removeFixture(fixture) }
        let controller = fixture.controller
        let scroll = controller.contentScrollView
        XCTAssertGreaterThan(scroll.contentSize.height, scroll.bounds.height)
        XCTAssertGreaterThan(controller.measuredContentHeight, controller.view.bounds.height)

        scroll.scrollRectToVisible(action.convert(action.bounds, to: scroll), animated: false)
        layout(fixture)
        let frame = action.convert(action.bounds, to: controller.view)
        XCTAssertGreaterThanOrEqual(frame.minY, controller.view.bounds.minY)
        XCTAssertLessThanOrEqual(frame.maxY, controller.view.bounds.maxY)
        let hitView = controller.view.hitTest(CGPoint(x: frame.midX, y: frame.midY), with: nil)
        XCTAssertTrue(hitView?.isDescendant(of: action) == true)
    }

    func testFinalActionKeepsBottomClearanceAsLocalSafeAreaChanges() throws {
        let content = UIView()
        content.heightAnchor.constraint(equalToConstant: 900).isActive = true
        let action = UIButton(type: .system)
        action.setTitle("Done", for: .normal)
        action.heightAnchor.constraint(equalToConstant: 44).isActive = true
        let fixture = makeFixture(size: CGSize(width: 360, height: 280), content: [content, action])
        defer { removeFixture(fixture) }
        let controller = fixture.controller
        let scroll = controller.contentScrollView
        for insets in [UIEdgeInsets.zero,
                       UIEdgeInsets(top: 0, left: 32, bottom: 30, right: 8),
                       UIEdgeInsets(top: 0, left: 8, bottom: 12, right: 32)] {
            controller.additionalSafeAreaInsets = insets
            layout(fixture)
            scroll.setContentOffset(CGPoint(x: -scroll.adjustedContentInset.left,
                                           y: scroll.contentSize.height + scroll.adjustedContentInset.bottom - scroll.bounds.height),
                                    animated: false)
            layout(fixture)
            let frame = action.convert(action.bounds, to: controller.view)
            let safeFrame = controller.view.safeAreaLayoutGuide.layoutFrame
            XCTAssertEqual(safeFrame.maxY - frame.maxY, 12, accuracy: 1)
            XCTAssertGreaterThanOrEqual(frame.minX, safeFrame.minX)
            XCTAssertLessThanOrEqual(frame.maxX, safeFrame.maxX)
            let hit = controller.view.hitTest(CGPoint(x: frame.midX, y: frame.midY), with: nil)
            XCTAssertTrue(hit?.isDescendant(of: action) == true)
        }
    }

    func testDynamicTypeChangeUpdatesTheNativeContentHeight() throws {
        let text = UILabel()
        text.numberOfLines = 0
        text.font = .preferredFont(forTextStyle: .body)
        text.adjustsFontForContentSizeCategory = true
        text.text = String(repeating: "Read this bulletin at your preferred text size. ", count: 8)
        let fixture = makeFixture(size: CGSize(width: 360, height: 600), content: [text])
        defer { removeFixture(fixture) }
        let originalHeight = fixture.controller.measuredContentHeight

        fixture.controller.traitOverrides.preferredContentSizeCategory = .accessibilityExtraExtraExtraLarge
        layout(fixture)
        XCTAssertGreaterThan(fixture.controller.measuredContentHeight, originalHeight)
    }

    func testRetainedContentDoesNotKeepTheNativeControllerAlive() throws {
        let manager = BLTNItemManager(rootItem: BLTNItem())
        var controller: NativeBulletinViewController? = NativeBulletinViewController()
        controller?.manager = manager
        controller?.loadViewIfNeeded()
        let retainedView: UIView = controller!.view
        let retainedSheet = controller!.sheetPresentationController
        weak let releasedController = controller
        controller = nil

        withExtendedLifetime((retainedView, retainedSheet, manager)) {
            XCTAssertNil(releasedController)
        }
    }

    private func makeFixture(size: CGSize, content: [UIView]) -> Fixture {
        let manager = BLTNItemManager(rootItem: BLTNItem())
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        let parent = UIViewController()
        window.rootViewController = parent
        window.isHidden = false
        parent.loadViewIfNeeded()
        let controller = NativeBulletinViewController()
        controller.manager = manager
        parent.addChild(controller)
        controller.traitOverrides.horizontalSizeClass = .regular
        controller.loadViewIfNeeded()
        controller.view.frame = parent.view.bounds
        parent.view.addSubview(controller.view)
        controller.didMove(toParent: parent)
        controller.updateCloseButton(isRequired: false)
        for view in content {
            view.translatesAutoresizingMaskIntoConstraints = false
            controller.contentStackView.addArrangedSubview(view)
        }
        let fixture = (window, parent, controller, manager)
        layout(fixture)
        return fixture
    }

    private func layout(_ fixture: Fixture, size: CGSize? = nil) {
        UIView.performWithoutAnimation {
            if let size {
                fixture.window.frame = CGRect(origin: .zero, size: size)
                fixture.parent.view.frame = fixture.window.bounds
                fixture.controller.view.frame = fixture.parent.view.bounds
            }
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
}
