import UIKit

/// A system sheet that displays the same item content as the custom card.
@available(iOS 26.0, *)
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
    private var scrollTopConstraint: NSLayoutConstraint!
    private var reservesCloseButton = false
    private var isDisplayingActivityIndicator = false
    private var isUpdatingDetents = false
    private var lastMeasurementWidth: CGFloat = 0

    private static let contentDetentIdentifier = UISheetPresentationController.Detent.Identifier("bulletinContent")

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
        if #available(iOS 27.0, *) {
            sheet.preferredPlacement = .trailing
        }
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
        stackTopConstraint = contentStackView.topAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.topAnchor, constant: 32)
        NSLayoutConstraint.activate([
            contentStackView.leadingAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            contentStackView.trailingAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            stackTopConstraint,
            contentStackView.bottomAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.bottomAnchor, constant: -24),
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
        updateContentHeight()
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

    private func updateContentHeight() {
        guard !isUpdatingDetents else { return }
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
        setMeasuredContentHeight(height)
    }

    private func contentHeight(for width: CGFloat) -> CGFloat {
        let stackHeight = contentStackView.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        let height = max(1, stackHeight + scrollTopConstraint.constant + stackTopConstraint.constant + 24)
        let scale = max(1, traitCollection.displayScale)
        return ceil(height * scale) / scale
    }

    private func setMeasuredContentHeight(_ height: CGFloat) {
        measuredContentHeight = height
        isUpdatingDetents = true
        preferredContentSize = CGSize(width: preferredContentSize.width, height: height)
        sheetPresentationController?.invalidateDetents()
        isUpdatingDetents = false
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
        // Capture the page height before its interface is hidden.
        if isViewLoaded { view.layoutIfNeeded() }
        isDisplayingActivityIndicator = true
        activityIndicator.color = color
        activityIndicator.startAnimating()
        activityIndicator.alpha = 1
        contentStackView.alpha = 0
        contentStackView.accessibilityElementsHidden = true
        closeButton.alpha = 0
        refreshInteraction()
        UIAccessibility.post(notification: .screenChanged, argument: activityIndicator)
    }

    func hideActivityIndicator() {
        isDisplayingActivityIndicator = false
        activityIndicator.stopAnimating()
        activityIndicator.alpha = 0
        contentStackView.alpha = 1
        contentStackView.accessibilityElementsHidden = false
        updateCloseButton(isRequired: manager?.needsCloseButton == true)
        refreshInteraction()
        refreshLayout()
    }

    func updateCloseButton(isRequired: Bool) {
        closeButton.alpha = isRequired && !isDisplayingActivityIndicator ? 1 : 0
        closeButton.isUserInteractionEnabled = isRequired && !isDisplayingActivityIndicator
        closeButton.accessibilityElementsHidden = !closeButton.isUserInteractionEnabled
        if isViewLoaded {
            reservesCloseButton = isRequired
            stackTopConstraint.constant = isRequired ? 0 : 32
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
        isModalInPresentation = !isDismissable || isDisplayingActivityIndicator || manager?.allowsSwipeInteraction != true
    }

    func cleanUpPresentation() {
        sheetPresentationController?.delegate = nil
        manager = nil
    }

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        isDismissable && !isDisplayingActivityIndicator && manager?.allowsSwipeInteraction == true
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        manager?.completeDismissal()
    }

    override func accessibilityPerformEscape() -> Bool {
        guard isDismissable && !isDisplayingActivityIndicator else { return false }
        manager?.dismissBulletin(animated: true)
        return true
    }

    @objc private func closeButtonTapped() {
        guard isDismissable && !isDisplayingActivityIndicator else { return }
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
