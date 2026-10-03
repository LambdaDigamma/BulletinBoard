import UIKit
import XCTest
@testable import BLTNBoard

@MainActor
final class BulletinCloseButtonTests: XCTestCase {
    func testSystemCloseForwardsItsActionAndKeepsTheTouchTarget() throws {
        let header = BulletinCloseButton(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let parent = UIViewController()
        window.rootViewController = parent
        parent.view.addSubview(header)
        window.isHidden = false
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        header.layoutIfNeeded()
        var invoked = false
        header.addAction(UIAction { _ in invoked = true }, for: .touchUpInside)
        var hit = header.hitTest(CGPoint(x: 282, y: 22), with: nil)
        while let view = hit, !(view is UIControl) {
            hit = view.superview
        }
        let nativeControl = try XCTUnwrap(hit as? UIControl)
        XCTAssertFalse(nativeControl === header)
        let center = nativeControl.convert(CGPoint(x: nativeControl.bounds.midX, y: nativeControl.bounds.midY), to: header)
        for offset: CGFloat in [-21, 21] {
            XCTAssertTrue(header.point(inside: CGPoint(x: center.x, y: center.y + offset), with: nil))
            XCTAssertTrue(header.point(inside: CGPoint(x: center.x + offset, y: center.y), with: nil))
        }
        nativeControl.sendActions(for: .touchUpInside)
        XCTAssertTrue(invoked)
    }

    func testSystemCloseAppearanceFollowsTheActualSurface() throws {
        let header = BulletinCloseButton(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let parent = UIViewController()
        window.rootViewController = parent
        parent.view.addSubview(header)
        window.isHidden = false
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        let bar = try XCTUnwrap(header.subviews.compactMap { $0 as? UINavigationBar }.first)
        XCTAssertNotNil(bar.topItem?.rightBarButtonItem)
        header.updateColors(for: .systemBackground)
        header.traitOverrides.userInterfaceStyle = .light
        header.setNeedsLayout()
        header.layoutIfNeeded()
        XCTAssertEqual(bar.traitCollection.userInterfaceStyle, .light)
        header.traitOverrides.userInterfaceStyle = .dark
        header.setNeedsLayout()
        header.layoutIfNeeded()
        XCTAssertEqual(bar.traitCollection.userInterfaceStyle, .dark)
        header.updateColors(for: .white)
        header.setNeedsLayout()
        header.layoutIfNeeded()
        XCTAssertEqual(bar.traitCollection.userInterfaceStyle, .light)
        header.updateColors(for: .black)
        header.setNeedsLayout()
        header.layoutIfNeeded()
        XCTAssertEqual(bar.traitCollection.userInterfaceStyle, .dark)
        XCTAssertFalse(header.isAccessibilityElement, "UIKit's Close item supplies accessibility")
        XCTAssertFalse(header.point(inside: CGPoint(x: 160, y: 22), with: nil), "Empty header must pass touches through")
    }
}
