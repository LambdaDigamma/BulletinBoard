/**
 *  BulletinBoard
 *  Copyright (c) 2017 - present Alexis Aubry. Licensed under the MIT license.
 */

import UIKit

/**
 * A view with rounded corners.
 */

class RoundedView: UIView, RoundedViewProtocol {

    // ARC-only cleanup must bypass isolated-deinit back-deployment on older iOS.
    nonisolated deinit {}

    override class var layerClass: AnyClass {
        return ContinuousMaskLayer.self
    }

}
