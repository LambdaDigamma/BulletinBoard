#if DEBUG
import UIKit
import XCTest
@testable import BLTNBoard

@MainActor
final class FrameworkPreviewTests: XCTestCase {
    func testPreviewTraitsReachBulletinOutsideHostHierarchy() throws {
        guard #available(iOS 17, *) else { throw XCTSkip("Framework previews require iOS 17") }
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first else {
            throw XCTSkip("The test host has no window scene")
        }
        let window = UIWindow(windowScene: scene)
        let parent = UIViewController()
        parent.overrideUserInterfaceStyle = .light
        let host = FrameworkPreviewController(scenario: .form, interfaceStyle: .dark,
                                              contentSize: .accessibilityExtraExtraExtraLarge,
                                              rightToLeft: true)
        window.rootViewController = parent
        parent.addChild(host)
        parent.view.addSubview(host.view)
        host.view.frame = parent.view.bounds
        host.didMove(toParent: parent)
        defer {
            parent.dismiss(animated: false)
            window.isHidden = true
            window.rootViewController = nil
        }
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        host.viewDidAppear(false)

        let bulletin = try XCTUnwrap(parent.presentedViewController ?? host.presentedViewController)
        XCTAssertEqual(bulletin.traitCollection.userInterfaceStyle, .dark)
        XCTAssertEqual(bulletin.traitCollection.preferredContentSizeCategory, .accessibilityExtraExtraExtraLarge)
        XCTAssertEqual(bulletin.traitCollection.layoutDirection, .rightToLeft)
    }

    func testPreviewFormKeepsEditedNameWhenViewsAreRebuilt() throws {
        guard #available(iOS 17, *) else { throw XCTSkip("Framework previews require iOS 17") }
        let item = FrameworkPreviewFormItem(title: "Name")
        let builder = BLTNInterfaceBuilder(appearance: item.appearance)
        let first = try XCTUnwrap(item.makeViewsUnderDescription(with: builder)?.first as? UITextField)
        first.text = "Taylor"
        item.tearDown()

        let rebuilt = try XCTUnwrap(item.makeViewsUnderDescription(with: builder)?.first as? UITextField)
        XCTAssertFalse(first === rebuilt)
        XCTAssertEqual(rebuilt.text, "Taylor")
        XCTAssertNil(first.delegate)
    }
}
#endif
