import UIKit

/// The interface the manager uses without taking over presentation geometry.
protocol BulletinPresentationHost: AnyObject {

    var manager: BLTNItemManager? { get set }
    var contentContainer: UIView { get }
    var contentStackView: UIStackView { get }
    var isDismissable: Bool { get set }

    func displayActivityIndicator(color: UIColor)
    func hideActivityIndicator()
    func updateCloseButton(isRequired: Bool)
    func refreshLayout(resetScrollPosition: Bool)
    func cancelInteractionIfNeeded()
    func refreshInteraction()
    func cleanUpPresentation()

}

extension BulletinPresentationHost {

    func refreshLayout() {
        refreshLayout(resetScrollPosition: false)
    }

}
