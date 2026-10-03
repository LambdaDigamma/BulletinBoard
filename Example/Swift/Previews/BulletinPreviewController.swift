/**
 *  BulletinBoard
 *  Copyright (c) 2017 - present Alexis Aubry. Licensed under the MIT license.
 */

#if DEBUG
import UIKit
import BLTNBoard

/// Presents one example item without the rest of the setup flow.
final class BulletinPreviewController: UIViewController {

    private let manager: BLTNItemManager
    private let backgroundImage: UIImage?
    private var hasPresentedBulletin = false

    init(item: BLTNItem, presentationStyle: BLTNPresentationStyle = .custom,
         backgroundImage: UIImage? = nil, interfaceStyle: UIUserInterfaceStyle = .unspecified) {
        manager = BLTNItemManager(rootItem: item)
        manager.presentationStyle = presentationStyle
        self.backgroundImage = backgroundImage
        super.init(nibName: nil, bundle: nil)
        overrideUserInterfaceStyle = interfaceStyle
    }

    required init?(coder: NSCoder) {
        fatalError("Use init(item:) for bulletin previews.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        if let backgroundImage {
            let imageView = UIImageView(image: backgroundImage)
            imageView.frame = view.bounds
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            view.addSubview(imageView)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !hasPresentedBulletin else { return }
        hasPresentedBulletin = true
        manager.showBulletin(above: self)
    }
}
#endif
