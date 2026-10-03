import UIKit

/// The item content and controls displayed in the native sheet.
final class BulletinContent {

    let stackView = UIStackView()
    let scrollView = UIScrollView()
    let closeButton = BulletinCloseButton()
    let activityIndicator = ActivityIndicator()

    init() {
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = false
        scrollView.contentInsetAdjustmentBehavior = .always
        scrollView.keyboardDismissMode = .interactive

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.style = .large
        activityIndicator.color = .black
        activityIndicator.isUserInteractionEnabled = false
        activityIndicator.alpha = 0
    }

    // Keep ARC cleanup compatible with the oldest supported iOS runtime.
    nonisolated deinit {}

}
