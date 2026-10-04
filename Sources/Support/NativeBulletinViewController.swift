import UIKit

/// A system sheet with a single content-height detent.
final class NativeBulletinViewController: UIViewController, BulletinPresentationHost, UISheetPresentationControllerDelegate {

    weak var manager: BLTNItemManager?

    private let content = BulletinContent()
    let contentContainer = UIView()
    var contentStackView: UIStackView { content.stackView }
    var contentScrollView: UIScrollView { content.scrollView }
    var closeButton: BulletinCloseButton { content.closeButton }
    var activityIndicator: ActivityIndicator { content.activityIndicator }

    var isDismissable = false {
        didSet { refreshInteraction() }
    }

    private(set) var measuredContentHeight: CGFloat = 0
    private var contentWidthConstraint: NSLayoutConstraint!
    private var stackTopConstraint: NSLayoutConstraint!
    private var stackBottomConstraint: NSLayoutConstraint!
    private var scrollTopConstraint: NSLayoutConstraint!
    private var reservesCloseButton = false
    private var isDisplayingActivityIndicator = false
    private var isUpdatingDetents = false
    private var lastMeasurementWidth: CGFloat = 0
    private(set) var isTransitioningItem = false
    private var defersContentHeight = false
    private var transitionGeneration = 0
    private var animatesItemTransition = false
    private var contentAnimator: UIViewPropertyAnimator?
    private var outgoingSnapshot: UIView?

    private static let contentDetentIdentifier = UISheetPresentationController.Detent.Identifier("bulletinContent")
    private static let contentVerticalClearance: CGFloat = 32

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        preferredContentSize = CGSize(width: 444, height: 0)
        configureSheet()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        modalPresentationStyle = .pageSheet
        preferredContentSize = CGSize(width: 444, height: 0)
        configureSheet()
    }

    nonisolated deinit {}

    private func configureSheet() {
        guard let sheet = sheetPresentationController else { return }
        sheet.delegate = self
        sheet.prefersPageSizing = false
        sheet.prefersEdgeAttachedInCompactHeight = true
        sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
        sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        #if !targetEnvironment(macCatalyst)
        if #available(iOS 26.1, *) {
            // Replace the sheet's glass, including the area outside the content safe area.
            sheet.backgroundEffect = UIColorEffect(color: .systemBackground)
        }
        #endif
        sheet.detents = [
            .custom(identifier: Self.contentDetentIdentifier) { [weak self] context in
                guard let self, self.measuredContentHeight > 0 else {
                    return context.maximumDetentValue
                }
                return min(self.measuredContentHeight, context.maximumDetentValue)
            },
        ]
        sheet.selectedDetentIdentifier = Self.contentDetentIdentifier
    }

    override func loadView() {
        super.loadView()
        // Provide an adaptive content background on every supported native-sheet release.
        view.backgroundColor = .systemBackground
        contentContainer.backgroundColor = .systemBackground
        contentContainer.accessibilityViewIsModal = true
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentContainer)
        NSLayoutConstraint.activate([
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainer.topAnchor.constraint(equalTo: view.topAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        contentContainer.addSubview(contentScrollView)
        scrollTopConstraint = contentScrollView.topAnchor.constraint(equalTo: contentContainer.topAnchor)
        NSLayoutConstraint.activate([
            contentScrollView.leadingAnchor.constraint(equalTo: contentContainer.safeAreaLayoutGuide.leadingAnchor),
            contentScrollView.trailingAnchor.constraint(equalTo: contentContainer.safeAreaLayoutGuide.trailingAnchor),
            scrollTopConstraint,
            contentScrollView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
        ])
        contentWidthConstraint = contentScrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: contentScrollView.frameLayoutGuide.widthAnchor)
        contentWidthConstraint.isActive = true
        contentScrollView.addSubview(contentStackView)
        contentStackView.spacing = 24
        stackTopConstraint = contentStackView.topAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.topAnchor,
                                                                  constant: Self.contentVerticalClearance)
        stackBottomConstraint = contentStackView.bottomAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.bottomAnchor,
                                                                        constant: -Self.contentVerticalClearance)
        NSLayoutConstraint.activate([
            contentStackView.leadingAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            contentStackView.trailingAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            stackTopConstraint,
            stackBottomConstraint,
        ])

        contentContainer.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.leadingAnchor.constraint(equalTo: contentScrollView.leadingAnchor),
            activityIndicator.trailingAnchor.constraint(equalTo: contentScrollView.trailingAnchor),
            activityIndicator.topAnchor.constraint(equalTo: contentScrollView.topAnchor),
            activityIndicator.bottomAnchor.constraint(equalTo: contentScrollView.bottomAnchor),
        ])

        contentContainer.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: contentContainer.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: contentContainer.safeAreaLayoutGuide.leadingAnchor),
            closeButton.trailingAnchor.constraint(equalTo: contentContainer.safeAreaLayoutGuide.trailingAnchor),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
        ])
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton.alpha = 0
        updateCloseButtonColors()

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self, UITraitUserInterfaceStyle.self]) { (self: NativeBulletinViewController, _) in
            self.updateCloseButtonColors()
            self.refreshLayout(resetScrollPosition: false)
        }
        refreshInteraction()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateHeaderHeight()
        updateBottomClearance()
        updateContentHeight(animated: isTransitioningItem && animatesItemTransition && UIView.areAnimationsEnabled)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        view.setNeedsLayout()
    }

    /// Give UIKit a content height before it creates the first sheet viewport.
    /// The final width is measured again after the native sheet has laid out.
    func prepareForPresentation(in presentingView: UIView) {
        guard isViewLoaded else { return }
        let usableWidth = presentingView.bounds.width
            - presentingView.safeAreaInsets.left - presentingView.safeAreaInsets.right
        let sheetWidth = min(preferredContentSize.width, usableWidth)
        let width = sheetWidth - 48
        guard width > 0 else { return }
        setMeasuredContentHeight(contentHeight(for: width))
    }

    private func updateContentHeight(animated: Bool = false) {
        guard !isUpdatingDetents, !defersContentHeight else { return }
        let insets = contentScrollView.adjustedContentInset
        let horizontalInsets = insets.left + insets.right
        if contentWidthConstraint.constant != -horizontalInsets {
            contentWidthConstraint.constant = -horizontalInsets
            view.setNeedsLayout()
        }
        let width = contentScrollView.bounds.width - horizontalInsets - 48
        guard width > 0 else { return }

        // Hidden content stays in the stack so loading keeps the last page height.
        guard !isDisplayingActivityIndicator || lastMeasurementWidth == 0 else { return }
        let height = contentHeight(for: width)
        let widthChanged = abs(lastMeasurementWidth - width) > 0.5
        lastMeasurementWidth = width
        guard widthChanged || abs(measuredContentHeight - height) > 0.5 else { return }
        setMeasuredContentHeight(height, animated: animated)
    }

    private func updateBottomClearance() {
        // The safe area supplies the clearance when it is large enough.
        let padding = max(0, Self.contentVerticalClearance - contentContainer.safeAreaInsets.bottom)
        guard stackBottomConstraint.constant != -padding else { return }
        stackBottomConstraint.constant = -padding
        view.setNeedsLayout()
    }

    private func contentHeight(for width: CGFloat) -> CGFloat {
        let stackHeight = contentStackView.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        // A custom detent excludes the bottom safe area; UIKit adds it to an edge-attached sheet.
        let height = max(1, stackHeight + scrollTopConstraint.constant + stackTopConstraint.constant - stackBottomConstraint.constant)
        let scale = max(1, traitCollection.displayScale)
        return ceil(height * scale) / scale
    }

    private func setMeasuredContentHeight(_ height: CGFloat, animated: Bool = false) {
        isUpdatingDetents = true
        let update = {
            self.measuredContentHeight = height
            self.preferredContentSize = CGSize(width: self.preferredContentSize.width, height: height)
            self.sheetPresentationController?.invalidateDetents()
        }
        if animated, let sheet = sheetPresentationController {
            sheet.animateChanges(update)
        } else {
            update()
        }
        isUpdatingDetents = false
    }

    /// Preserve the visible page before its item releases its views.
    func beginItemTransition(animated: Bool) {
        cancelItemTransition()
        defersContentHeight = true
        view.layoutIfNeeded()
        animatesItemTransition = animated && UIView.areAnimationsEnabled
            && !UIAccessibility.isReduceMotionEnabled && presentingViewController != nil
        if animatesItemTransition {
            outgoingSnapshot = contentContainer.snapshotView(afterScreenUpdates: false)
            if let snapshot = outgoingSnapshot {
                snapshot.frame = contentContainer.frame
                snapshot.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                snapshot.isUserInteractionEnabled = false
                snapshot.accessibilityElementsHidden = true
                view.addSubview(snapshot)
            }
        }
        isTransitioningItem = true
        updateContentVisibility()
        refreshInteraction()
    }

    /// Fade the old page out, resize with UIKit, then reveal the new page.
    /// UIKit owns the resize duration. Display callbacks follow the content fade.
    func finishItemTransition(willDisplay: @escaping () -> Bool, completion: @escaping () -> Void) {
        let generation = transitionGeneration
        let reveal: () -> Void = { [weak self] in
            guard let self, self.transitionGeneration == generation else { return }
            self.contentAnimator = nil
            self.outgoingSnapshot?.removeFromSuperview()
            self.outgoingSnapshot = nil
            // Layout at the final width while detent updates are still suspended.
            self.view.layoutIfNeeded()
            self.defersContentHeight = false
            self.updateContentHeight(animated: self.animatesItemTransition)
            guard willDisplay(), self.transitionGeneration == generation else { return }

            let finish: () -> Void = { [weak self] in
                guard let self, self.transitionGeneration == generation else { return }
                self.contentAnimator = nil
                self.isTransitioningItem = false
                self.updateContentVisibility()
                self.refreshInteraction()
                completion()
            }
            if self.animatesItemTransition {
                let animator = UIViewPropertyAnimator(duration: 0.25, curve: .easeInOut) { [weak self] in
                    self?.updateContentVisibility(revealing: true)
                }
                self.contentAnimator = animator
                animator.addCompletion { position in
                    if position == .end { finish() }
                }
                animator.startAnimation()
            } else {
                finish()
            }
        }
        if animatesItemTransition, let snapshot = outgoingSnapshot {
            let animator = UIViewPropertyAnimator(duration: 0.15, curve: .easeOut) {
                snapshot.alpha = 0
            }
            contentAnimator = animator
            animator.addCompletion { position in
                if position == .end { reveal() }
            }
            animator.startAnimation()
        } else {
            reveal()
        }
    }

    func cancelItemTransition() {
        transitionGeneration += 1
        contentAnimator?.stopAnimation(true)
        contentAnimator = nil
        outgoingSnapshot?.removeFromSuperview()
        outgoingSnapshot = nil
        isTransitioningItem = false
        defersContentHeight = false
        animatesItemTransition = false
        if isViewLoaded { updateContentVisibility() }
        refreshInteraction()
    }

    private func updateContentVisibility(revealing: Bool = false) {
        let visible = !isTransitioningItem || revealing
        contentStackView.alpha = visible && !isDisplayingActivityIndicator ? 1 : 0
        activityIndicator.alpha = visible && isDisplayingActivityIndicator ? 1 : 0
        closeButton.alpha = visible && reservesCloseButton && !isDisplayingActivityIndicator ? 1 : 0
        contentContainer.isUserInteractionEnabled = !isTransitioningItem && !isDisplayingActivityIndicator
        contentStackView.accessibilityElementsHidden = isTransitioningItem || isDisplayingActivityIndicator
        closeButton.isUserInteractionEnabled = !isTransitioningItem && reservesCloseButton && !isDisplayingActivityIndicator
        closeButton.accessibilityElementsHidden = !closeButton.isUserInteractionEnabled
    }

    func refreshLayout(resetScrollPosition: Bool = false) {
        guard isViewLoaded else { return }
        if resetScrollPosition {
            let insets = contentScrollView.adjustedContentInset
            contentScrollView.setContentOffset(CGPoint(x: -insets.left, y: -insets.top), animated: false)
        }
        view.setNeedsLayout()
    }

    func displayActivityIndicator(color: UIColor) {
        // An interrupted page has not changed the visible sheet height yet.
        // Keep that height, remove its snapshot, and show loading immediately.
        if isTransitioningItem {
            cancelItemTransition()
        } else if isViewLoaded {
            view.layoutIfNeeded()
        }
        isDisplayingActivityIndicator = true
        activityIndicator.color = color
        activityIndicator.startAnimating()
        updateContentVisibility()
        refreshInteraction()
        UIAccessibility.post(notification: .screenChanged, argument: activityIndicator)
    }

    func hideActivityIndicator() {
        isDisplayingActivityIndicator = false
        activityIndicator.stopAnimating()
        updateCloseButton(isRequired: manager?.needsCloseButton == true)
        updateContentVisibility()
        refreshInteraction()
        refreshLayout()
    }

    func updateCloseButton(isRequired: Bool) {
        reservesCloseButton = isRequired
        updateContentVisibility()
        if isViewLoaded {
            stackTopConstraint.constant = isRequired ? 0 : Self.contentVerticalClearance
            updateHeaderHeight()
            view.setNeedsLayout()
        }
    }

    private func updateHeaderHeight() {
        // Keep scrolling content below the full touch target, including asymmetric safe areas.
        scrollTopConstraint.constant = reservesCloseButton ? contentContainer.safeAreaInsets.top + 68 : 0
    }

    private func updateCloseButtonColors() {
        closeButton.updateColors(for: .systemBackground)
    }

    func cancelInteractionIfNeeded() {
        // UIKit owns native interactive transitions.
    }

    func refreshInteraction() {
        // Native sheet swipe and outside-tap dismissal share one system policy.
        isModalInPresentation = !isDismissable || isTransitioningItem || isDisplayingActivityIndicator || manager?.allowsSwipeInteraction != true
    }

    func cleanUpPresentation() {
        cancelItemTransition()
        sheetPresentationController?.delegate = nil
        manager = nil
    }

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        isDismissable && !isTransitioningItem && !isDisplayingActivityIndicator && manager?.allowsSwipeInteraction == true
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        manager?.completeDismissal()
    }

    override func accessibilityPerformEscape() -> Bool {
        guard isDismissable && !isTransitioningItem && !isDisplayingActivityIndicator else { return false }
        manager?.dismissBulletin(animated: true)
        return true
    }

    @objc private func closeButtonTapped() {
        guard isDismissable && !isTransitioningItem && !isDisplayingActivityIndicator else { return }
        manager?.dismissBulletin(animated: true)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        manager?.statusBarAppearance == .lightContent ? .lightContent : .default
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        manager?.statusBarAnimation ?? .fade
    }

    override var prefersStatusBarHidden: Bool {
        manager?.statusBarAppearance == .hidden
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        manager?.hidesHomeIndicator ?? false
    }

}
