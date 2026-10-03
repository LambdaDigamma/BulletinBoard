#if DEBUG
import SwiftUI
import UIKit

@available(iOS 17, *)
#Preview("Page Size Transitions") {
    FrameworkPreviewController(scenario: .pageSizes)
}

@available(iOS 17, *)
#Preview("Actions") {
    FrameworkPreviewController(scenario: .actions)
}

@available(iOS 17, *)
#Preview("Form and Loading", traits: .fixedLayout(width: 320, height: 568)) {
    FrameworkPreviewController(scenario: .form)
}

@available(iOS 17, *)
#Preview("Form - Dark") {
    FrameworkPreviewController(scenario: .form, interfaceStyle: .dark)
}

@available(iOS 17, *)
#Preview("Long Content - Short", traits: .fixedLayout(width: 568, height: 320)) {
    FrameworkPreviewController(scenario: .longContent)
}

@available(iOS 17, *)
#Preview("Large Text") {
    FrameworkPreviewController(scenario: .longContent, contentSize: .accessibilityExtraExtraExtraLarge)
}

@available(iOS 17, *)
#Preview("Right to Left", traits: .fixedLayout(width: 320, height: 568)) {
    FrameworkPreviewController(scenario: .form, rightToLeft: true)
}

#endif
