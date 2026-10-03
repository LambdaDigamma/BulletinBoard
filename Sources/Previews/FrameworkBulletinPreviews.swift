#if DEBUG
import SwiftUI
import UIKit

@available(iOS 17, *)
#Preview("Custom - Actions") {
    FrameworkPreviewController(scenario: .actions)
}

@available(iOS 17, *)
#Preview("Custom - Form and Loading", traits: .fixedLayout(width: 320, height: 568)) {
    FrameworkPreviewController(scenario: .form)
}

@available(iOS 17, *)
#Preview("Custom - Form - Dark") {
    FrameworkPreviewController(scenario: .form, interfaceStyle: .dark)
}

@available(iOS 17, *)
#Preview("Custom - Long Content - Short", traits: .fixedLayout(width: 568, height: 320)) {
    FrameworkPreviewController(scenario: .longContent)
}

@available(iOS 17, *)
#Preview("Custom - Large Text") {
    FrameworkPreviewController(scenario: .longContent, contentSize: .accessibilityExtraExtraExtraLarge)
}

@available(iOS 17, *)
#Preview("Custom - Right to Left", traits: .fixedLayout(width: 320, height: 568)) {
    FrameworkPreviewController(scenario: .form, rightToLeft: true)
}

@available(iOS 26, *)
#Preview("Native - Actions") {
    FrameworkPreviewController(scenario: .actions, presentationStyle: .nativeSheet)
}

@available(iOS 26, *)
#Preview("Native - Form and Loading") {
    FrameworkPreviewController(scenario: .form, presentationStyle: .nativeSheet)
}

@available(iOS 26, *)
#Preview("Native - Form - Dark") {
    FrameworkPreviewController(scenario: .form, presentationStyle: .nativeSheet, interfaceStyle: .dark)
}

@available(iOS 26, *)
#Preview("Native - Long Content - Short", traits: .fixedLayout(width: 568, height: 320)) {
    FrameworkPreviewController(scenario: .longContent, presentationStyle: .nativeSheet)
}
#endif
