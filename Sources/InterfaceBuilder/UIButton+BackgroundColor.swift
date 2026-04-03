/**
 *  BulletinBoard
 *  Copyright (c) 2017 - present Alexis Aubry. Licensed under the MIT license.
 */

import UIKit

extension UIButton {

    /**
     * Sets a solid background color for the button.
     */

    func setBackgroundColor(_ color: UIColor, forState controlState: UIControl.State) {

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        let colorImage = renderer.image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        setBackgroundImage(colorImage, for: controlState)

    }

}
