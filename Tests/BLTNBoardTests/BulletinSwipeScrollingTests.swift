import UIKit
import XCTest
@testable import BLTNBoard

@MainActor
final class BulletinSwipeScrollingTests: XCTestCase {
    private var manager: BLTNItemManager!
    private var parent: UIViewController!
    private var controller: BulletinViewController!
    private var interaction: BulletinSwipeInteractionController!

    private func prepare() {
        manager = BLTNItemManager(rootItem: BLTNPageItem(title: "Scrollable bulletin"))
        parent = UIViewController()
        controller = BulletinViewController()
        controller.manager = manager
        parent.addChild(controller)
        setSizeClass(.compact)
        parent.view.addSubview(controller.view)
        controller.didMove(toParent: parent)
        controller.isDismissable = true
        controller.contentScrollView.frame = CGRect(x: 0, y: 0, width: 300, height: 200)
        controller.contentScrollView.contentSize = CGSize(width: 300, height: 1000)
        controller.contentScrollView.isScrollEnabled = true
        interaction = BulletinSwipeInteractionController()
        interaction.wire(to: controller)
    }

    private func cleanUp() {
        interaction = nil
        controller = nil
        parent = nil
        manager = nil
    }

    func testUpwardDragScrollsInsteadOfDismissing() {
        prepare()
        defer { cleanUp() }
        let pan = VelocityPanGestureRecognizer()
        pan.testVelocity = CGPoint(x: 0, y: -300)
        XCTAssertFalse(interaction.gestureRecognizerShouldBegin(pan))
    }

    func testDownwardDragDismissesOnlyAtTheTop() {
        prepare()
        defer { cleanUp() }
        let pan = VelocityPanGestureRecognizer()
        pan.testVelocity = CGPoint(x: 0, y: 300)
        controller.contentScrollView.contentOffset.y = 80
        XCTAssertFalse(interaction.gestureRecognizerShouldBegin(pan))

        controller.contentScrollView.contentOffset.y = -controller.contentScrollView.adjustedContentInset.top
        XCTAssertTrue(interaction.gestureRecognizerShouldBegin(pan))
    }

    func testNonDismissableScrollableCardKeepsItsContentDrag() {
        prepare()
        defer { cleanUp() }
        controller.isDismissable = false
        let pan = VelocityPanGestureRecognizer()
        pan.testVelocity = CGPoint(x: 0, y: 300)
        XCTAssertFalse(interaction.gestureRecognizerShouldBegin(pan))
    }

    func testRegularWidthScrollableCardKeepsItsContentDrag() {
        prepare()
        defer { cleanUp() }
        setSizeClass(.regular)
        let pan = VelocityPanGestureRecognizer()
        pan.testVelocity = CGPoint(x: 0, y: 300)
        XCTAssertFalse(interaction.gestureRecognizerShouldBegin(pan))
    }

    func testShortCardRetainsItsDragInteraction() {
        prepare()
        defer { cleanUp() }
        controller.contentScrollView.contentSize.height = 160
        let pan = VelocityPanGestureRecognizer()
        pan.testVelocity = CGPoint(x: 0, y: -300)
        XCTAssertTrue(interaction.gestureRecognizerShouldBegin(pan))
    }

    private func setSizeClass(_ sizeClass: UIUserInterfaceSizeClass) {
        if #available(iOS 17.0, *) {
            controller.traitOverrides.horizontalSizeClass = sizeClass
        } else {
            parent.setOverrideTraitCollection(UITraitCollection(horizontalSizeClass: sizeClass), forChild: controller)
        }
    }
}
