/**
 *  BulletinBoard
 *  Copyright (c) 2017 - present Alexis Aubry. Licensed under the MIT license.
 */

import UIKit

/**
 * A view controller that displays a card at the bottom of the screen.
 */

final class BulletinViewController: UIViewController, UIGestureRecognizerDelegate, BulletinPresentationHost {

    /// The object managing the view controller.
    weak var manager: BLTNItemManager?

    // MARK: - UI Elements

    /// The subview that contains the contents of the card.
    let contentView = RoundedView()

    private let content = BulletinContent()

    var contentContainer: UIView { contentView }

    /// The button that allows the users to close the bulletin.
    var closeButton: BulletinCloseButton { content.closeButton }

    /**
     * The stack view displaying the content of the card.
     *
     * - warning: You should not customize the distribution, axis and alignment of the stack, as this
     * may break the layout of the card.
     */

    var contentStackView: UIStackView { content.stackView }

    /// Keeps every item reachable when the available region is shorter than the content.
    var contentScrollView: UIScrollView { content.scrollView }

    /// The view covering the content. Generated in `loadBackgroundView`.
    var backgroundView: BulletinBackgroundView!

    /// The activity indicator.
    var activityIndicator: ActivityIndicator { content.activityIndicator }

    // MARK: - Dismissal Support Properties

    /// Indicates whether the bulletin can be dismissed by a tap outside the card.
    var isDismissable: Bool = false

    /// The snapshot view of the content used during dismissal.
    var activeSnapshotView: UIView?

    /// The active swipe interaction controller.
    var swipeInteractionController: BulletinSwipeInteractionController!

    // MARK: - Private Interface Elements

    // Compact constraints
    fileprivate var leadingConstraint: NSLayoutConstraint!
    fileprivate var trailingConstraint: NSLayoutConstraint!
    fileprivate var centerXConstraint: NSLayoutConstraint!
    fileprivate var maxWidthConstraint: NSLayoutConstraint!

    // Regular constraints
    fileprivate var widthConstraint: NSLayoutConstraint!
    fileprivate var centerYConstraint: NSLayoutConstraint!

    // Stack view constraints
    fileprivate var stackLeadingConstraint: NSLayoutConstraint!
    fileprivate var stackTrailingConstraint: NSLayoutConstraint!
    fileprivate var stackBottomConstraint: NSLayoutConstraint!

    // Position constraints
    fileprivate var minYConstraint: NSLayoutConstraint!
    fileprivate var contentTopConstraint: NSLayoutConstraint!
    fileprivate var contentBottomConstraint: NSLayoutConstraint!

    private let availableRegionGuide = UILayoutGuide()
    private var regionLeftConstraint: NSLayoutConstraint!
    private var regionTopConstraint: NSLayoutConstraint!
    private var regionWidthConstraint: NSLayoutConstraint!
    private var regionHeightConstraint: NSLayoutConstraint!
    private var maxHeightConstraint: NSLayoutConstraint!
    private var keyboardLimitConstraint: NSLayoutConstraint!
    private var naturalHeightConstraint: NSLayoutConstraint!
    private var preferredRegionPoint: CGPoint?
    private var lastLayoutRegion: CGRect?
    private var isInPlace = false
    private var needsResponderVisibility = true
    private var lastScrollSize = CGSize.zero
    private var lastContentSize = CGSize.zero
    private weak var lastVisibleResponder: UIView?

    // MARK: - Deinit

    // ARC-only cleanup must bypass isolated-deinit back-deployment on older iOS.
    nonisolated deinit {}

}

// MARK: - Lifecycle

extension BulletinViewController {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpLayout(with: traitCollection)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        /// Animate status bar appearance when hiding
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        })

    }

    override func loadView() {

        super.loadView()
        view.backgroundColor = .clear

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        recognizer.delegate = self
        recognizer.cancelsTouchesInView = false
        recognizer.delaysTouchesEnded = false

        view.addGestureRecognizer(recognizer)

        contentView.accessibilityViewIsModal = true
        contentView.clipsToBounds = true
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(contentView)

        view.addLayoutGuide(availableRegionGuide)
        regionLeftConstraint = availableRegionGuide.leftAnchor.constraint(equalTo: view.leftAnchor)
        regionTopConstraint = availableRegionGuide.topAnchor.constraint(equalTo: view.topAnchor)
        regionWidthConstraint = availableRegionGuide.widthAnchor.constraint(equalToConstant: view.bounds.width)
        regionHeightConstraint = availableRegionGuide.heightAnchor.constraint(equalToConstant: view.bounds.height)
        NSLayoutConstraint.activate([regionLeftConstraint, regionTopConstraint, regionWidthConstraint, regionHeightConstraint])

        // Content View

        centerXConstraint = contentView.centerXAnchor.constraint(equalTo: availableRegionGuide.centerXAnchor)

        centerYConstraint = contentView.centerYAnchor.constraint(equalTo: availableRegionGuide.centerYAnchor)
        centerYConstraint.priority = .defaultHigh
        centerYConstraint.constant = 2500

        widthConstraint = contentView.widthAnchor.constraint(equalToConstant: 444)
        widthConstraint.priority = UILayoutPriority(999)

        // Close button

        contentView.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16).isActive = true
        closeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        closeButton.isUserInteractionEnabled = true

        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)

        // Content Stack View

        contentScrollView.translatesAutoresizingMaskIntoConstraints = false
        contentScrollView.alwaysBounceVertical = false
        contentScrollView.contentInsetAdjustmentBehavior = .always
        contentScrollView.keyboardDismissMode = .interactive
        contentView.addSubview(contentScrollView)
        NSLayoutConstraint.activate([
            contentScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentScrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentScrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            contentScrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: contentScrollView.frameLayoutGuide.widthAnchor),
        ])
        contentScrollView.addSubview(contentStackView)

        naturalHeightConstraint = contentScrollView.frameLayoutGuide.heightAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.heightAnchor)
        naturalHeightConstraint.priority = .fittingSizeLevel
        naturalHeightConstraint.isActive = true

        stackLeadingConstraint = contentStackView.leadingAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.leadingAnchor)
        stackLeadingConstraint.isActive = true

        stackTrailingConstraint = contentStackView.trailingAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.trailingAnchor)
        stackTrailingConstraint.isActive = true

        minYConstraint = contentView.topAnchor.constraint(greaterThanOrEqualTo: availableRegionGuide.topAnchor)
        minYConstraint.isActive = true
        minYConstraint.priority = UILayoutPriority.required

        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.distribution = .fill

        // Activity Indicator

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(activityIndicator)
        activityIndicator.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        activityIndicator.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        activityIndicator.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        activityIndicator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

        activityIndicator.style = .large
        activityIndicator.color = .black
        activityIndicator.isUserInteractionEnabled = false

        activityIndicator.alpha = 0

        // Vertical Position

        stackBottomConstraint = contentStackView.bottomAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.bottomAnchor)
        contentTopConstraint = contentScrollView.contentLayoutGuide.topAnchor.constraint(equalTo: contentStackView.topAnchor)

        stackBottomConstraint.isActive = true
        contentTopConstraint.isActive = true

        // Configuration

        configureContentView()
        setUpKeyboardLogic()

        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitHorizontalSizeClass.self, UITraitVerticalSizeClass.self, UITraitLayoutDirection.self]) { (self: BulletinViewController, _) in
                self.view.setNeedsLayout()
            }
        }

        if #available(iOS 27.1, *) {
            view.addInteraction(UIHingeInteraction { [weak self] _, _ in
                self?.view.setNeedsLayout()
            })
        }

        contentView.bringSubviewToFront(closeButton)

    }

    @available(iOS 11.0, *)
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        view.setNeedsLayout()
    }

    /// Configure content view with customizations.

    fileprivate func configureContentView() {

        guard let manager = self.manager else {
            fatalError("Trying to set up the content view, but the BulletinViewController is not managed.")
        }

        contentView.backgroundColor = manager.backgroundColor
        contentView.cornerRadius = CGFloat((manager.cardCornerRadius ?? 12).doubleValue)
        closeButton.updateColors(for: manager.backgroundColor)

        let cardPadding = manager.edgeSpacing.rawValue

        // Set left and right padding
        leadingConstraint = contentView.leadingAnchor.constraint(equalTo: availableRegionGuide.leadingAnchor,
                                                                 constant: cardPadding)

        trailingConstraint = contentView.trailingAnchor.constraint(equalTo: availableRegionGuide.trailingAnchor,
                                                                   constant: -cardPadding)

        // Set maximum width with padding

        maxWidthConstraint = contentView.widthAnchor.constraint(lessThanOrEqualTo: availableRegionGuide.widthAnchor,
                                                                constant: -(cardPadding * 2))

        maxWidthConstraint.priority = .required
        maxWidthConstraint.isActive = true

        maxHeightConstraint = contentView.heightAnchor.constraint(lessThanOrEqualTo: availableRegionGuide.heightAnchor)
        maxHeightConstraint.isActive = true

        contentBottomConstraint = contentView.bottomAnchor.constraint(equalTo: availableRegionGuide.bottomAnchor)

        contentBottomConstraint.constant = 1000
        contentBottomConstraint.isActive = true

    }

    // MARK: - Gesture Recognizer

    internal func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view?.isDescendant(of: contentView) == true {
            return false
        }

        return true
    }

}

// MARK: - Layout

extension BulletinViewController {

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateLayoutRegion()
        setUpLayout(with: traitCollection)
        updateCornerRadius()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Keyboard and child safe-area guides have their final geometry after layout.
        updateLayoutRegion()
        let scrollInsets = contentScrollView.adjustedContentInset
        let insetHeight = scrollInsets.top + scrollInsets.bottom
        if naturalHeightConstraint.constant != insetHeight {
            naturalHeightConstraint.constant = insetHeight
            view.setNeedsLayout()
        }
        let responder = firstResponder(in: contentStackView)
        let scrollGeometryChanged = lastScrollSize != contentScrollView.bounds.size
            || lastContentSize != contentScrollView.contentSize
        if needsResponderVisibility || scrollGeometryChanged || responder !== lastVisibleResponder,
           manager?.currentItem.shouldRespondToKeyboardChanges == true,
           let responder {
            let rect = responder.convert(responder.bounds, to: contentScrollView).insetBy(dx: -8, dy: -8)
            contentScrollView.scrollRectToVisible(rect, animated: false)
        }
        needsResponderVisibility = false
        lastScrollSize = contentScrollView.bounds.size
        lastContentSize = contentScrollView.contentSize
        lastVisibleResponder = responder
    }

    private func firstResponder(in view: UIView) -> UIView? {
        if view.isFirstResponder { return view }
        for child in view.subviews {
            if let responder = firstResponder(in: child) { return responder }
        }
        return nil
    }

    /// Read at gesture time, after the scroll view has laid out its content.
    var canScrollContent: Bool {
        let insets = contentScrollView.adjustedContentInset
        return contentScrollView.isScrollEnabled
            && contentScrollView.contentSize.height + insets.top + insets.bottom > contentScrollView.bounds.height + 1
    }

    private func updateLayoutRegion() {
        let safeFrame = view.bounds.inset(by: view.safeAreaInsets)
        var usableFrame = safeFrame
        let respondsToKeyboard = manager?.currentItem.shouldRespondToKeyboardChanges == true
        let keyboardFrame = view.keyboardLayoutGuide.layoutFrame
        let keyboardOverlap = safeFrame.intersection(keyboardFrame)
        let keyboardIsVisible = !keyboardOverlap.isNull && !keyboardOverlap.isEmpty

        if respondsToKeyboard && keyboardIsVisible {
            usableFrame.size.height = max(0, keyboardFrame.minY - usableFrame.minY)
        }

        var divisions: [CGRect] = []
        if #available(iOS 27.1, *) {
            divisions = view.reservedRegions(kind: .division).filter(\.isActive).map(\.frame)
        }

        var region = BulletinLayoutRegion.select(in: usableFrame, excluding: divisions,
                                                layoutDirection: view.effectiveUserInterfaceLayoutDirection,
                                                preferredPoint: preferredRegionPoint)
        preferredRegionPoint = divisions.isEmpty ? nil : CGPoint(x: region.midX, y: region.midY)

        // Only the card surface can extend under the home indicator. Its content keeps its own safe inset.
        if manager?.hidesHomeIndicator == true,
           traitCollection.horizontalSizeClass == .compact,
           !(respondsToKeyboard && keyboardIsVisible),
           abs(region.maxY - safeFrame.maxY) < 1 {
            region.size.height = max(0, view.bounds.maxY - region.minY)
        }

        if let previousRegion = lastLayoutRegion, previousRegion != region, isInPlace {
            swipeInteractionController?.cancelIfNeeded()
        }

        let padding = min(defaultBottomMargin, max(0, (region.width - 1) / 2))
        let verticalPadding = min(defaultBottomMargin, max(0, (region.height - 1) / 2))
        leadingConstraint.constant = padding
        trailingConstraint.constant = -padding
        maxWidthConstraint.constant = -(padding * 2)
        minYConstraint.constant = verticalPadding
        maxHeightConstraint.constant = -(verticalPadding * 2)
        keyboardLimitConstraint.constant = -verticalPadding
        // Keep the guide connected while hidden so its first keyboard update triggers layout.
        keyboardLimitConstraint.isActive = isInPlace && respondsToKeyboard
        if isInPlace { contentBottomConstraint.constant = -min(bottomMargin(), verticalPadding) }

        let preferredStackPadding: CGFloat = traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular ? 32 : 24
        let stackPadding = min(preferredStackPadding, max(0, (region.width - padding * 2) / 2))
        stackLeadingConstraint.constant = stackPadding
        stackTrailingConstraint.constant = -stackPadding
        stackBottomConstraint.constant = -stackPadding

        if lastLayoutRegion != region {
            lastLayoutRegion = region
            regionLeftConstraint.constant = region.minX - view.bounds.minX
            regionTopConstraint.constant = region.minY - view.bounds.minY
            regionWidthConstraint.constant = max(0, region.width)
            regionHeightConstraint.constant = max(0, region.height)
            needsResponderVisibility = true
            view.setNeedsLayout()
        }
    }

    /// Refreshes per-item keyboard policy and content sizing without storing scene geometry.
    func refreshLayout(resetScrollPosition: Bool = false) {
        guard isViewLoaded else { return }
        if resetScrollPosition { contentScrollView.setContentOffset(.zero, animated: false) }
        needsResponderVisibility = true
        view.setNeedsLayout()
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {

        super.willTransition(to: newCollection, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            self.setUpLayout(with: newCollection)
            self.view.setNeedsLayout()
        })

    }

    fileprivate func setUpLayout(with traitCollection: UITraitCollection) {

        switch traitCollection.horizontalSizeClass {
        case .regular:
            leadingConstraint.isActive = false
            trailingConstraint.isActive = false
            contentBottomConstraint.isActive = false
            centerXConstraint.isActive = true
            centerYConstraint.isActive = true
            widthConstraint.isActive = true

        case .compact:
            leadingConstraint.isActive = true
            trailingConstraint.isActive = true
            contentBottomConstraint.isActive = true
            centerXConstraint.isActive = false
            centerYConstraint.isActive = false
            widthConstraint.isActive = false

        default:
            break
        }

        switch (traitCollection.verticalSizeClass, traitCollection.horizontalSizeClass) {
        case (.regular, .regular):
            contentTopConstraint.constant = -32
            contentStackView.spacing = 32

        default:
            contentTopConstraint.constant = -24
            contentStackView.spacing = 24

        }

    }

    // MARK: - Transition Adaptivity

    var defaultBottomMargin: CGFloat {
        return manager?.edgeSpacing.rawValue ?? 12
    }

    func bottomMargin() -> CGFloat {
        var bottomMargin: CGFloat = manager?.edgeSpacing.rawValue ?? 12

        if manager?.hidesHomeIndicator == true {
            bottomMargin = manager?.edgeSpacing.rawValue == 0 ? 0 : 6
        }

        return bottomMargin

    }

    /// Moves the content view to its final location on the screen. Use during presentation.
    func moveIntoPlace() {

        isInPlace = true
        contentBottomConstraint.constant = -bottomMargin()
        centerYConstraint.constant = 0
        view.setNeedsLayout()

        view.layoutIfNeeded()
        contentView.layoutIfNeeded()
        backgroundView.layoutIfNeeded()

    }

    // MARK: - Presentation/Dismissal

    /// Dismisses the presnted BulletinViewController if `isDissmisable` is set to `true`.
    @discardableResult
    func dismissIfPossible() -> Bool {

        guard isDismissable else {
            return false
        }

        manager?.dismissBulletin(animated: true)
        return true

    }

    // MARK: - Touch Events

    @objc fileprivate func handleTap(recognizer: UITapGestureRecognizer) {
        dismissIfPossible()
    }

    // MARK: - Accessibility

    override func accessibilityPerformEscape() -> Bool {
        return dismissIfPossible()
    }

}

// MARK: - System Elements

extension BulletinViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if let manager = manager {
            switch manager.statusBarAppearance {
            case .lightContent:
                return .lightContent
            case .automatic:
                return manager.backgroundViewStyle.rawValue.isDark ? .lightContent : .default
            default:
                break
            }
        }

        return .default
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return manager?.statusBarAnimation ?? .fade
    }

    override var prefersStatusBarHidden: Bool {
        return manager?.statusBarAppearance == .hidden
    }

    @available(iOS 11.0, *)
    override var prefersHomeIndicatorAutoHidden: Bool {
        return manager?.hidesHomeIndicator ?? false
    }

}

// MARK: - Safe Area

extension BulletinViewController {

    fileprivate func updateCornerRadius() {

        if manager?.edgeSpacing.rawValue == 0 {
            contentView.cornerRadius = 0
            return
        }

        contentView.cornerRadius = CGFloat((manager?.cardCornerRadius ?? 12).doubleValue)

    }

}

// MARK: - Background

extension BulletinViewController {

    /// Creates a new background view for the bulletin.
    func loadBackgroundView() {
        backgroundView = BulletinBackgroundView(style: manager?.backgroundViewStyle ?? .dimmed)
    }

}

// MARK: - Activity Indicator

extension BulletinViewController {

    /// Displays the activity indicator.
    func displayActivityIndicator(color: UIColor) {

        activityIndicator.color = color
        activityIndicator.startAnimating()

        let animations = {
            self.activityIndicator.alpha = 1
            self.contentStackView.alpha = 0
            self.closeButton.alpha = 0
        }

        UIView.animate(withDuration: 0.25, animations: animations) { _ in
            UIAccessibility.post(notification: .screenChanged, argument: self.activityIndicator)
        }

    }

    /// Hides the activity indicator.
    func hideActivityIndicator() {

        activityIndicator.stopAnimating()
        activityIndicator.alpha = 0

        let needsCloseButton = manager?.needsCloseButton == true

        let animations = {
            self.activityIndicator.alpha = 0
            self.updateCloseButton(isRequired: needsCloseButton)
        }

        UIView.animate(withDuration: 0.25, animations: animations)

    }

}

// MARK: - Close Button

extension BulletinViewController {

    func updateCloseButton(isRequired: Bool) {
        isRequired ? showCloseButton() : hideCloseButton()
    }

    func showCloseButton() {
        closeButton.alpha = 1
        closeButton.isUserInteractionEnabled = true
        closeButton.accessibilityElementsHidden = false
    }

    func hideCloseButton() {
        closeButton.alpha = 0
        closeButton.isUserInteractionEnabled = false
        closeButton.accessibilityElementsHidden = true
    }

    @objc func closeButtonTapped() {
        manager?.dismissBulletin(animated: true)
    }

}

// MARK: - Transitions

extension BulletinViewController: UIViewControllerTransitioningDelegate {

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BulletinPresentationAnimationController(style: manager?.backgroundViewStyle ?? .dimmed)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BulletinDismissAnimationController()
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning)
        -> UIViewControllerInteractiveTransitioning? {

            guard manager?.allowsSwipeInteraction == true else {
                return nil
            }

            let isEligible = swipeInteractionController.isInteractionInProgress
            return isEligible ? swipeInteractionController : nil

    }

    /// Creates a new view swipe interaction controller and wires it to the content view.
    func refreshSwipeInteractionController() {

        if let recognizer = swipeInteractionController?.panGestureRecognizer {
            contentView.removeGestureRecognizer(recognizer)
        }
        swipeInteractionController = nil

        guard manager?.allowsSwipeInteraction == true else {
            return
        }

        swipeInteractionController = BulletinSwipeInteractionController()
        swipeInteractionController.wire(to: self)

    }

    func cancelInteractionIfNeeded() {
        swipeInteractionController?.cancelIfNeeded()
    }

    func refreshInteraction() {
        refreshSwipeInteractionController()
    }

    func cleanUpPresentation() {
        backgroundView = nil
        transitioningDelegate = nil
        manager = nil
    }

    /// Prepares the view controller for dismissal.
    func prepareForDismissal(displaying snapshot: UIView) {
        activeSnapshotView = snapshot
    }

}

// MARK: - Keyboard

extension BulletinViewController {
    func setUpKeyboardLogic() {
        view.keyboardLayoutGuide.followsUndockedKeyboard = true
        if #available(iOS 17.0, *) {
            view.keyboardLayoutGuide.usesBottomSafeArea = manager?.hidesHomeIndicator != true
        }
        keyboardLimitConstraint = contentView.bottomAnchor.constraint(lessThanOrEqualTo: view.keyboardLayoutGuide.topAnchor)
        // The region updates in the same layout cycle. A transient keyboard update must not break required constraints.
        keyboardLimitConstraint.priority = UILayoutPriority(999)
    }
}
