import UIKit

@MainActor
final class VelocityPanGestureRecognizer: UIPanGestureRecognizer {
    var testVelocity = CGPoint.zero

    override func velocity(in view: UIView?) -> CGPoint {
        testVelocity
    }
}
