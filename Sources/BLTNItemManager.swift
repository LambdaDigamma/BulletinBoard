/**
 *  BulletinBoard
 *  Copyright (c) 2017 - present Alexis Aubry. Licensed under the MIT license.
 */

import UIKit

/**
 * An object that manages the presentation of a bulletin.
 *
 * You create a bulletin manager using the `init(rootItem:)` initializer, where `rootItem` is the
 * first bulletin item to display. An item represents the contents displayed on a single card.
 *
 * The manager works like a navigation controller. You can push new items to the stack to display them,
 * and pop existing ones to go back.
 *
 * You must call the `prepare` method before displaying the view controller.
 *
 * `BLTNItemManager` must only be used from the main thread.
 */

public final class BLTNItemManager {

    /// Bulletin view controller.
    fileprivate var bulletinController: (UIViewController & BulletinPresentationHost)!

    /// The active presenter. Internal access also permits focused presentation tests.
    var presentationController: UIViewController? { bulletinController }

    // MARK: - Background

    /**
     * The background color of the bulletin card. Defaults to `systemBackground` on iOS 13
     * and white on older versions of the OS.
     *
     * Set this value before presenting the bulletin. Changing it after will have no effect.
     */

    public var backgroundColor: UIColor = .systemBackground

    /**
     * The style of the view covering the content. Defaults to `.dimmed`.
     *
     * Set this value before presenting the bulletin. Changing it after will have no effect.
     */

    public var backgroundViewStyle: BLTNBackgroundViewStyle = .dimmed

    // MARK: - Status Bar

    /**
     * The style of status bar to use with the bulltin. Defaults to `.automatic`.
     *
     * Set this value before presenting the bulletin. Changing it after will have no effect.
     */

    public var statusBarAppearance: BLTNStatusBarAppearance = .automatic

    /**
     * The style of status bar animation. Defaults to `.fade`.
     *
     * Set this value before presenting the bulletin. Changing it after will have no effect.
     */

    public var statusBarAnimation: UIStatusBarAnimation = .fade

    /**
     * Whether the home indicator should be hidden. Defaults to false.
     * The card surface can extend to the bottom edge. Content keeps its safe-area inset.
     *
     * Set this value before presenting the bulletin. Changing it after will have no effect.
     */

    public var hidesHomeIndicator: Bool = false

    // MARK: - Card Presentation

    /**
     * The presenter to use. Defaults to the custom BulletinBoard card.
     *
     * Set this value before showing the bulletin. The native sheet is available on iOS 26
     * and later; earlier releases use the custom card. UIKit controls native sheet styling
     * and keyboard behavior. See `BLTNPresentationStyle.nativeSheet` for the differences.
     */

    public var presentationStyle: BLTNPresentationStyle = .custom

    /**
     * The spacing between the usable region and the edge of the card. Defaults to regular.
     *
     * Set this value before presenting the bulletin. Changing it after will have no effect.
     */

    public var edgeSpacing: BLTNSpacing = .regular

    /**
     * The rounded corner radius of the bulletin card. Defaults to 12, independently of system safe areas.
     *
     * Set this value before calling `prepare`. Changing it after will have no effect.
     */

    public var cardCornerRadius: NSNumber?

    /**
     * Whether swipe to dismiss should be allowed. Defaults to true.
     *
     * If you set this value to true, the user will be able to drag the card, and swipe down to
     * dismiss it (if allowed by the current item).
     *
     * If you set this value to false, no pan gesture will be recognized, and swipe to dismiss
     * won't be available.
     */

    public var allowsSwipeInteraction: Bool = true {
        didSet {
            bulletinController?.cancelInteractionIfNeeded()
            bulletinController?.refreshInteraction()
        }
    }
    
    /**
     * Tells us if a bulletin is currently being shown. Defaults to false
     */

    public var isShowingBulletin: Bool {
        return bulletinController?.presentingViewController != nil
    }

    // MARK: - Private Properties

    var currentItem: BLTNItem

    fileprivate let rootItem: BLTNItem
    fileprivate var itemsStack: [BLTNItem]
    fileprivate var previousItem: BLTNItem?
    fileprivate var presentingWindow: UIWindow?

    fileprivate var isPrepared: Bool = false
    fileprivate var isPreparing: Bool = false
    fileprivate var shouldDisplayActivityIndicator: Bool = false
    fileprivate var lastActivityIndicatorColor: UIColor = .label
    private var interfaceGeneration = 0
    private var isDismissingBulletin = false
    private var hasPreparedPresentation = false
    private var activeItem: BLTNItem?

    private var shouldUseNativeSheet: Bool {
        if #available(iOS 26.0, *) {
            return presentationStyle == .nativeSheet
        }
        return false
    }

    // MARK: - Initialization

    /**
     * Creates a bulletin manager and sets the first item to display.s
     *
     * - parameter rootItem: The first item to display.
     */

    public init(rootItem: BLTNItem) {

        self.rootItem = rootItem
        self.itemsStack = []
        self.currentItem = rootItem

    }

    nonisolated deinit {
        // Keep items alive until their UI cleanup runs. Do not capture the dying manager.
        let items = [rootItem] + itemsStack
        let preparedItem = activeItem
        let wasPrepared = hasPreparedPresentation
        let cleanUp: @MainActor @Sendable () -> Void = {
            if wasPrepared {
                preparedItem?.tearDown()
                preparedItem?.manager = nil
            } else {
                for item in items {
                    Self.tearDownItemsChain(startingAt: item)
                }
            }
        }
        // UIKit can release us synchronously outside a Swift task. Avoid the broken
        // isolated-deinit runtime on older iOS, but retain MainActor cleanup.
        if Thread.isMainThread {
            MainActor.assumeIsolated { cleanUp() }
        } else {
            Task { @MainActor in cleanUp() }
        }
    }

}

// MARK: - Interacting with the Bulletin

extension BLTNItemManager {

    /**
     * Prepares the bulletin interface and displays the root item.
     *
     * This method must be called before any other interaction with the bulletin.
     */

    fileprivate func prepare() {

        assertIsMainThread()

        if #available(iOS 26.0, *), shouldUseNativeSheet {
            bulletinController = NativeBulletinViewController()
        } else {
            let customController = BulletinViewController()
            bulletinController = customController
            customController.modalPresentationStyle = .overFullScreen
            customController.transitioningDelegate = customController
            customController.manager = self
            customController.loadBackgroundView()
        }
        bulletinController.manager = self
        bulletinController.setNeedsStatusBarAppearanceUpdate()
        bulletinController.setNeedsUpdateOfHomeIndicatorAutoHidden()
        
        isPrepared = true
        hasPreparedPresentation = true
        isPreparing = true
        shouldDisplayActivityIndicator = rootItem.shouldStartWithActivityIndicator

        refreshCurrentItemInterface()
        isPreparing = false

    }

    /**
     * Presents a view controller above the bulletin card.
     *
     * This is useful if you want to present an alert or a Safari view contoller in response to user
     * action.
     *
     * - parameter viewController: The view controller to present.
     * - parameter animated: Whether presentation should be animated.
     * - parameter completion: An optional completion block to run after presentation
     * has completed. Defaults to `nil`.
     */

    public func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        assertIsPrepared()
        self.bulletinController.present(viewController, animated: animated, completion: completion)
    }

    /**
     * Performs an operation with the bulletin content view and returns the result.
     *
     * Use this as an opportunity to customize the behavior of the content view (e.g. add motion effects).
     *
     * You must not store a reference to the view, or modify its layout (add subviews, add contraints, ...) as this
     * could break the bulletin.
     *
     * Use this feature sparingly.
     *
     * - parameter transform: The code to execute with the content view.
     * - warning: If you save the content view outside of the `transform` closure, an exception will be raised.
     */

    @discardableResult
    public func withContentView<Result>(_ transform: (UIView) throws -> Result) rethrows -> Result {

        assertIsPrepared()
        assertIsMainThread()

        let contentView = bulletinController.contentContainer
        let initialRetainCount = CFGetRetainCount(contentView)

        let result = try transform(contentView)
        let finalRetainCount = CFGetRetainCount(contentView)

        precondition(initialRetainCount == finalRetainCount,
                     "The content view was saved outside of the transform closure. This is not allowed.")

        return result

    }

    /**
     * Hides the contents of the stack and displays an activity indicator view.
     *
     * Use this method if you need to perform a long task or fetch some data before changing the item.
     *
     * Displaying the loading indicator does not change the height of the page or the current item. It will disable
     * dismissal by tapping and swiping to allow the task to complete and avoid resource deallocation.
     *
     * - parameter color: The color of the activity indicator to display. Defaults to .label on iOS 13 and .black on older systems.
     *
     * Displaying the loading indicator does not change the height of the page or the current item.
     */

    public func displayActivityIndicator(color: UIColor? = nil) {

        assertIsPrepared()
        assertIsMainThread()

        shouldDisplayActivityIndicator = true
        lastActivityIndicatorColor = color ?? defaultActivityIndicatorColor

        bulletinController.displayActivityIndicator(color: lastActivityIndicatorColor)
    }

    /// Provides a default color for activity indicator views.
    private var defaultActivityIndicatorColor: UIColor {
        return .label
    }

    /**
     * Hides the activity indicator and displays the current item.
     *
     * You can also call one of `popItem`, `popToRootItem` and `pushItem` if you need to hide the activity
     * indicator and change the current item.
     */

    public func hideActivityIndicator() {

        assertIsPrepared()
        assertIsMainThread()

        shouldDisplayActivityIndicator = false
        bulletinController.cancelInteractionIfNeeded()
        refreshCurrentItemInterface(elementsChanged: false)

    }

    /**
     * Displays a new item after the current one.
     * - parameter item: The item to display.
     */

    public func push(item: BLTNItem) {

        assertIsPrepared()
        assertIsMainThread()

        previousItem = currentItem
        itemsStack.append(item)

        currentItem = item

        shouldDisplayActivityIndicator = item.shouldStartWithActivityIndicator
        refreshCurrentItemInterface()

    }

    /**
     * Removes the current item from the stack and displays the previous item.
     */

    public func popItem() {

        assertIsPrepared()
        assertIsMainThread()

        guard let previousItem = itemsStack.popLast() else {
            popToRootItem()
            return
        }

        self.previousItem = previousItem

        guard let currentItem = itemsStack.last else {
            popToRootItem()
            return
        }

        self.currentItem = currentItem

        shouldDisplayActivityIndicator = currentItem.shouldStartWithActivityIndicator
        refreshCurrentItemInterface()

    }

    /**
     * Removes items from the stack until a specific item is found.
     * - parameter item: The item to seek.
     * - parameter orDismiss: If true, dismiss bullein if not found. Otherwise popToRootItem()
     */
    
    public func popTo(item: BLTNItem, orDismiss: Bool) {
        
        assertIsPrepared()
        assertIsMainThread()
        
        for index in 0..<itemsStack.count  {
            
            if itemsStack[index] === item {
                
                self.currentItem = itemsStack[index]
                shouldDisplayActivityIndicator = currentItem.shouldStartWithActivityIndicator
                refreshCurrentItemInterface()
                
                for removeIndex in (index+1..<itemsStack.count).reversed() {
                    let removeItem = itemsStack.remove(at: removeIndex)
                    // Items below the displayed page were torn down when that page changed.
                    if removeItem.manager === self {
                        Self.tearDownItemsChain(startingAt: removeItem)
                    }
                }
                return
            }
        }
        
        if item !== rootItem, orDismiss {
            dismissBulletin(animated: true)
        } else {
            popToRootItem()
        }
    }
    
    /**
     * Removes all the items from the stack and displays the root item.
     */

    public func popToRootItem() {

        assertIsPrepared()
        assertIsMainThread()

        guard currentItem !== rootItem else {
            return
        }

        previousItem = currentItem
        currentItem = rootItem

        itemsStack = []

        shouldDisplayActivityIndicator = rootItem.shouldStartWithActivityIndicator
        refreshCurrentItemInterface()

    }

    /**
     * Displays the next item, if the `next` property of the current item is set.
     *
     * - warning: If you call this method but `next` is `nil`, an exception will be raised.
     */

    public func displayNextItem() {

        guard let next = currentItem.next else {
            preconditionFailure("Calling BLTNItemManager.displayNextItem, but the current item has no nextItem.")
        }

        push(item: next)

    }

}

// MARK: - Presentation / Dismissal

extension BLTNItemManager {

    /**
     * Presents the bulletin above the specified view controller.
     *
     * - parameter presentingVC: The view controller to use to present the bulletin.
     * - parameter animated: Whether to animate presentation. Defaults to `true`.
     * - parameter completion: An optional block to execute after presentation. Default to `nil`.
     */

    public func showBulletin(above presentingVC: UIViewController,
                                       animated: Bool = true,
                                     completion: (() -> Void)? = nil) {

        assertIsMainThread()
        precondition(!isDismissingBulletin && bulletinController?.presentingViewController == nil,
                     "Attempt to present a Bulletin that is already presented or being dismissed.")
        self.prepare()

        let isDetached = bulletinController.presentingViewController == nil
        assert(isDetached, "Attempt to present a Bulletin that is already presented.")

        assertIsPrepared()
        assertIsMainThread()
        bulletinController.loadViewIfNeeded()

        let refreshActivityIndicator = shouldDisplayActivityIndicator && isDetached

        if refreshActivityIndicator {
            bulletinController.displayActivityIndicator(color: lastActivityIndicatorColor)
        }

        bulletinController.modalPresentationCapturesStatusBarAppearance = true
        let controller = bulletinController!
        let item = currentItem
        let generation = interfaceGeneration
        if #available(iOS 26.0, *), let nativeController = controller as? NativeBulletinViewController {
            nativeController.prepareForPresentation(in: presentingVC.view)
            presentingVC.present(controller, animated: animated) {
                if self.isCurrentInterface(controller: controller, item: item, generation: generation) {
                    item.willDisplay()
                    if self.isCurrentInterface(controller: controller, item: item, generation: generation) {
                        item.onDisplay()
                    }
                }
                completion?()
            }
        } else {
            presentingVC.present(controller, animated: animated, completion: completion)
        }

    }
    
    /**
     * Presents the bulletin on top of your application window.
     *
     * - parameter application: The application in which to display the bulletin. (normally: UIApplication.shared)
     * - parameter animated: Whether to animate presentation. Defaults to `true`.
     * - parameter completion: An optional block to execute after presentation. Default to `nil`.
     */
    
    /**
     * Presents the bulletin on top of the specified window scene.
     *
     * - parameter windowScene: The window scene in which to display the bulletin.
     * - parameter animated: Whether to animate presentation. Defaults to `true`.
     * - parameter completion: An optional block to execute after presentation. Default to `nil`.
     */

    public func showBulletin(in windowScene: UIWindowScene,
                             animated: Bool = true,
                             completion: (() -> Void)? = nil) {
        assertIsMainThread()
        if shouldUseNativeSheet {
            let visibleWindows = windowScene.windows.filter { !$0.isHidden && $0.rootViewController != nil }
            let window = visibleWindows.first(where: \.isKeyWindow) ?? visibleWindows.last
            guard var presenter = window?.rootViewController else {
                assertionFailure("Unable to find a view controller in the supplied window scene.")
                return
            }
            while let presented = presenter.presentedViewController, !presented.isBeingDismissed {
                presenter = presented
            }
            showBulletin(above: presenter, animated: animated, completion: completion)
            return
        }
        let topWindow = windowScene.windows.last
        showBulletin(in: windowScene, above: topWindow, animated: animated, completion: completion)
    }

    @available(*, deprecated, message: "Use showBulletin(in:animated:completion:) with a UIWindowScene.")
    public func showBulletin(in application: UIApplication,
                             animated: Bool = true,
                             completion: (() -> Void)? = nil) {
        assertIsMainThread()
        let windowScenes = application.connectedScenes.compactMap { $0 as? UIWindowScene }
        let windowScene = windowScenes.first { scene in
            scene.windows.contains(where: \.isKeyWindow)
        } ?? windowScenes.first {
            $0.activationState == .foregroundActive
        } ?? windowScenes.first {
            $0.activationState == .foregroundInactive
        } ?? windowScenes.first

        guard let windowScene else {
            assertionFailure("Unable to find a window scene to present the bulletin.")
            return
        }

        showBulletin(in: windowScene, animated: animated, completion: completion)
    }

    private func showBulletin(in windowScene: UIWindowScene,
                              above topWindow: UIWindow?,
                              animated: Bool,
                              completion: (() -> Void)?) {
        assert(presentingWindow == nil, "Attempt to present a Bulletin on top of another Bulletin window. Make sure to dismiss any existing bulletin before calling this method.")
        presentingWindow = UIWindow(windowScene: windowScene)
        presentingWindow?.rootViewController = UIViewController()

        if let topWindow {
            presentingWindow?.windowLevel = topWindow.windowLevel + 1
        }
        
        presentingWindow?.makeKeyAndVisible()
        
        if let vc = presentingWindow?.rootViewController {
            self.showBulletin(above: vc, animated: animated, completion: completion)
        }
        
    }

    /**
     * Dismisses the bulletin and clears the current page. You will have to call `prepare` before
     * presenting the bulletin again.
     *
     * This method will call the `dismissalHandler` block of the current item if it was set.
     *
     * - parameter animated: Whether to animate dismissal. Defaults to `true`.
     */

    public func dismissBulletin(animated: Bool = true) {

        guard !isDismissingBulletin else { return }
        assertIsPrepared()
        assertIsMainThread()

        isDismissingBulletin = true
        interfaceGeneration += 1
        tearDownCurrentItem()

        let controller = bulletinController!
        isPrepared = false
        controller.dismiss(animated: animated) {
            guard self.bulletinController === controller else { return }
            self.completeDismissal()
        }

    }

    /**
     * Tears down the view controller and item stack after dismissal is finished.
     */

    func completeDismissal() {
        guard let controller = bulletinController else { return }
        let dismissedItem = currentItem
        interfaceGeneration += 1
        isPrepared = false
        tearDownCurrentItem()

        for arrangedSubview in controller.contentStackView.arrangedSubviews {
            controller.contentStackView.removeArrangedSubview(arrangedSubview)
            arrangedSubview.removeFromSuperview()
        }
        
        presentingWindow?.isHidden = true
        presentingWindow = nil

        controller.cleanUpPresentation()
        bulletinController = nil

        currentItem = self.rootItem
        itemsStack.removeAll()
        previousItem = nil
        isDismissingBulletin = false
        dismissedItem.onDismiss()

    }

    private func tearDownCurrentItem() {
        let item = activeItem
        activeItem = nil
        if item?.manager === self {
            item?.tearDown()
            item?.manager = nil
        }
    }

}

// MARK: - Transitions

extension BLTNItemManager {

    var needsCloseButton: Bool {
        return currentItem.isDismissable && currentItem.requiresCloseButton
    }

    /// Refreshes the interface for the current item.
    fileprivate func refreshCurrentItemInterface(elementsChanged: Bool = true) {

        interfaceGeneration += 1
        let generation = interfaceGeneration
        let controller = bulletinController!
        let item = currentItem

        if #available(iOS 26.0, *), controller is NativeBulletinViewController {
            refreshNativeItemInterface(elementsChanged: elementsChanged, controller: controller,
                                       item: item, generation: generation)
            return
        }

        bulletinController.isDismissable = false
        bulletinController.cancelInteractionIfNeeded()
        bulletinController.refreshInteraction()

        let showActivityIndicator = self.shouldDisplayActivityIndicator
        let contentAlpha: CGFloat =  showActivityIndicator ? 0 : 1

        // Tear down old item

        let oldArrangedSubviews = bulletinController.contentStackView.arrangedSubviews
        let oldHideableArrangedSubviews = recursiveArrangedSubviews(in: oldArrangedSubviews)

        if elementsChanged {
            activeItem?.tearDown()
            activeItem?.manager = nil
            activeItem = nil
            previousItem = nil
        }

        // Create new views

        let newArrangedSubviews = elementsChanged ? currentItem.makeArrangedSubviews() : oldArrangedSubviews
        let newHideableArrangedSubviews = recursiveArrangedSubviews(in: newArrangedSubviews)

        if elementsChanged {

            currentItem.setUp()
            currentItem.manager = self
            activeItem = currentItem

            for arrangedSubview in newHideableArrangedSubviews {
                arrangedSubview.isHidden = isPreparing ? false : true
            }

            for arrangedSubview in newArrangedSubviews {
                bulletinController.contentStackView.addArrangedSubview(arrangedSubview)
            }

        }

        // Animate transition

        let animationDuration = isPreparing ? 0 : 0.75
        let transitionAnimationChain = AnimationChain(duration: animationDuration)

        let hideSubviewsAnimationPhase = AnimationPhase(relativeDuration: 1/3, curve: .linear)

        hideSubviewsAnimationPhase.block = {
            guard self.isCurrentInterface(controller: controller, item: item, generation: generation) else { return }

            if !showActivityIndicator {
                self.bulletinController.hideActivityIndicator()
            }

            for arrangedSubview in oldArrangedSubviews {
                arrangedSubview.alpha = 0
            }

            for arrangedSubview in newArrangedSubviews {
                arrangedSubview.alpha = 0
            }

        }

        let displayNewItemsAnimationPhase = AnimationPhase(relativeDuration: 1/3, curve: .linear)

        displayNewItemsAnimationPhase.block = {
            guard self.isCurrentInterface(controller: controller, item: item, generation: generation) else { return }

            for arrangedSubview in oldHideableArrangedSubviews {
                arrangedSubview.isHidden = true
            }

            for arrangedSubview in newHideableArrangedSubviews {
                arrangedSubview.isHidden = false
            }

        }
        
        displayNewItemsAnimationPhase.completionHandler = {
            guard self.isCurrentInterface(controller: controller, item: item, generation: generation) else { return }
            item.willDisplay()
        }

        let finalAnimationPhase = AnimationPhase(relativeDuration: 1/3, curve: .linear)

        finalAnimationPhase.block = {
            guard self.isCurrentInterface(controller: controller, item: item, generation: generation) else { return }

            let currentElements = elementsChanged ? newArrangedSubviews : oldArrangedSubviews
            self.bulletinController.contentStackView.alpha = contentAlpha
            self.bulletinController.updateCloseButton(isRequired: self.needsCloseButton && !showActivityIndicator)

            for arrangedSubview in currentElements {
                arrangedSubview.alpha = contentAlpha
            }

        }

        finalAnimationPhase.completionHandler = {
            guard self.isCurrentInterface(controller: controller, item: item, generation: generation) else { return }

            self.bulletinController.isDismissable = self.currentItem.isDismissable && (showActivityIndicator == false)

            if elementsChanged {

                self.currentItem.onDisplay()

                guard self.isCurrentInterface(controller: controller, item: item, generation: generation) else { return }

                for arrangedSubview in oldArrangedSubviews {
                    self.bulletinController.contentStackView.removeArrangedSubview(arrangedSubview)
                    arrangedSubview.removeFromSuperview()
                }

                self.bulletinController.refreshLayout(resetScrollPosition: true)

            }

            UIAccessibility.post(notification: .screenChanged, argument: newArrangedSubviews.first)

        }

        // Perform animation

        if elementsChanged {
            transitionAnimationChain.add(hideSubviewsAnimationPhase)
            transitionAnimationChain.add(displayNewItemsAnimationPhase)
        } else {
            bulletinController.hideActivityIndicator()
        }

        transitionAnimationChain.add(finalAnimationPhase)
        bulletinController.refreshLayout()
        transitionAnimationChain.start()

    }

    /// Reuses item construction and callbacks while UIKit owns the sheet transition.
    private func refreshNativeItemInterface(elementsChanged: Bool,
                                            controller: UIViewController & BulletinPresentationHost,
                                            item: BLTNItem,
                                            generation: Int) {
        controller.isDismissable = false
        controller.loadViewIfNeeded()

        if elementsChanged {
            if let oldItem = activeItem {
                oldItem.tearDown()
                oldItem.manager = nil
            }
            activeItem = nil
            previousItem = nil

            for subview in controller.contentStackView.arrangedSubviews {
                controller.contentStackView.removeArrangedSubview(subview)
                subview.removeFromSuperview()
            }
            for subview in item.makeArrangedSubviews() {
                controller.contentStackView.addArrangedSubview(subview)
            }
            item.setUp()
            item.manager = self
            activeItem = item
        }

        if shouldDisplayActivityIndicator {
            controller.updateCloseButton(isRequired: needsCloseButton)
            controller.displayActivityIndicator(color: lastActivityIndicatorColor)
        } else {
            controller.hideActivityIndicator()
            controller.updateCloseButton(isRequired: needsCloseButton)
        }
        controller.refreshLayout(resetScrollPosition: elementsChanged)

        if elementsChanged && !isPreparing {
            item.willDisplay()
            guard isCurrentInterface(controller: controller, item: item, generation: generation) else { return }
        }
        controller.isDismissable = item.isDismissable && !shouldDisplayActivityIndicator
        if elementsChanged && !isPreparing {
            item.onDisplay()
            guard isCurrentInterface(controller: controller, item: item, generation: generation) else { return }
        }
        UIAccessibility.post(notification: .screenChanged,
                             argument: controller.contentStackView.arrangedSubviews.first)
    }

    private func isCurrentInterface(controller: UIViewController & BulletinPresentationHost,
                                    item: BLTNItem, generation: Int) -> Bool {
        isPrepared && bulletinController === controller && currentItem === item && interfaceGeneration == generation
    }

    /// Tears down every item on the stack starting from the specified item.
    fileprivate static func tearDownItemsChain(startingAt item: BLTNItem) {

        item.tearDown()
        item.manager = nil

        if let next = item.next {
            Self.tearDownItemsChain(startingAt: next)
            item.next = nil
        }

    }

    /// Returns all the arranged subviews.
    private func recursiveArrangedSubviews(in views: [UIView]) -> [UIView] {

        var arrangedSubviews: [UIView] = []

        for view in views {

            if let stack = view as? UIStackView {
                arrangedSubviews.append(stack)
                let recursiveViews = self.recursiveArrangedSubviews(in: stack.arrangedSubviews)
                arrangedSubviews.append(contentsOf: recursiveViews)
            } else {
                arrangedSubviews.append(view)
            }

        }

        return arrangedSubviews

    }

}

// MARK: - Utilities

extension BLTNItemManager {

    fileprivate func assertIsMainThread() {
        precondition(Thread.isMainThread, "BLTNItemManager must only be used from the main thread.")
    }

    fileprivate func assertIsPrepared() {
        precondition(isPrepared, "You must call the `prepare` function before interacting with the bulletin.")
    }

}
