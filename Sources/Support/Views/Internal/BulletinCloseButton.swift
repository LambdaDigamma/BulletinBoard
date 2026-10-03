/**
 *  BulletinBoard
 *  Copyright (c) 2017 - present Alexis Aubry. Licensed under the MIT license.
 */

import UIKit

/// Hosts UIKit's standard navigation-bar Close item without a navigation controller.
final class BulletinCloseButton: UIControl {
    private let navigationBar = UINavigationBar()
    private var surfaceColor: UIColor = .systemBackground

    // UIKit can release this control outside a Swift task.
    nonisolated deinit {}

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureNavigationBar()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureNavigationBar()
    }

    private func configureNavigationBar() {
        // The system item supplies its symbol, pressed state, localized label, and glass on iOS 26.
        isAccessibilityElement = false
        let item = UINavigationItem()
        item.rightBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { [weak self] _ in
            self?.sendActions(for: .touchUpInside)
        })
        navigationBar.setItems([item], animated: false)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.tintColor = .label
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(navigationBar)
        NSLayoutConstraint.activate([
            navigationBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            navigationBar.topAnchor.constraint(equalTo: topAnchor),
            navigationBar.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: BulletinCloseButton, _) in
            self.updateAppearance()
        }
        updateAppearance()
    }

    func updateColors(for surfaceColor: UIColor) {
        self.surfaceColor = surfaceColor
        updateAppearance()
    }

    private func updateAppearance() {
        // A custom card can use a light surface in a dark app, or the reverse.
        let surface = surfaceColor.resolvedColor(with: traitCollection)
        navigationBar.traitOverrides.userInterfaceStyle = surface.needsDarkText ? .light : .dark
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard super.point(inside: point, with: event) else { return false }
        // Empty header space must keep passing touches to the content and sheet gestures.
        var hit = navigationBar.hitTest(convert(point, to: navigationBar), with: event)
        while let view = hit, view !== navigationBar {
            if view is UIControl { return true }
            hit = view.superview
        }
        return false
    }
}
