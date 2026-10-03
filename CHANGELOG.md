# _BulletinBoard_ Changelog
## Unreleased

### New Features
- Use native UIKit sheets on every supported release, from iOS 17. Keep one content-height stop and scroll long content. Request trailing placement on iOS 27 and use a solid adaptive sheet surface on iOS 26.1 and later.
- Add seven debug-only framework Xcode previews for page-size transitions, actions, alerts, forms, loading, push/pop, scrolling, large text, dark mode, and right-to-left layout. Keep the fixtures independent of the demo app.
- Animate sheet height during page changes and fade content out and in. Apply changes directly with Reduce Motion. Cancel stale transitions after a new page, loading, or dismissal.
- Let the startup loading indicator adapt to light and dark mode.

### Fixes
- Use UIKit's navigation-bar Close item with standard appearance, accessibility, and interaction. Keep scrolling content below its fixed header.
- Preserve controls and values during loading, show the spinner immediately if loading interrupts a fade, and clean up each active item once after dismissal.
- Adapt demo controls and galleries to live width changes.

### Changed Behavior
- Require Xcode 27.1 or later and iOS 17 or later.
- Remove the custom presenter, its fold-region selection, background options, corners, and gestures. UIKit controls sheet placement and keyboard movement. Tall native sheets can span a horizontal Duo fold.
- Keep `presentationStyle` (including `.custom`), `backgroundColor`, `backgroundViewStyle`, `edgeSpacing`, `cardCornerRadius`, and `shouldRespondToKeyboardChanges` as deprecated compatibility settings with no effect.
- Present scene bulletins from an existing application controller. Setting `allowsSwipeInteraction = false` also blocks native outside-tap dismissal.
- Remove obsolete presenter and background selectors from the demo. Retain direct example entries and update all previews to native sheets.

[#1](https://github.com/LambdaDigamma/BulletinBoard/pull/1)

## 🔖 v6.1.1
### Fixes
- Prevent isolated destructor crashes on older iOS when UIKit releases animation objects outside a Swift task.
- Keep item teardown on MainActor and preserve task-local values after a background owner releases the manager.

### Changes
- Enable the two extra Swift Approachable Concurrency features in the Swift package.
- Add six regression tests and an iOS simulator test script. Tests pass on iOS 18.6 and iOS 27.1 with Thread Sanitizer under Xcode 27 RC. Xcode 26.3 validation remains pending.

## 🔖 v6.1.0
### Changes
- Adopt Swift 6 language mode, SwiftPM tools 6.2, and complete strict concurrency.
- Add scene-based bulletin presentation with a `UIWindowScene` API.
- Remove Objective-C API support and the Objective-C compatibility header.
- Remove the Objective-C demo app target, scheme, and resources.
- Remove Objective-C-era `NSObject` inheritance from Swift-only manager and configuration types.

## 🔖 v5.0.0
### Changes
- Require iOS 11.0
- Support for Swift Package Manager

### Fixes
- Fix the background view origin when presenting
[#183](https://github.com/alexaubry/BulletinBoard/pull/183)

## 🔖 v4.1.2
### Fixes
- Fix crash for iOS 11 and under
[#177](https://github.com/alexaubry/BulletinBoard/issues/177)

## 🔖 v4.1.1
### Changes
- Do not use external resources for close button

### Fixes
- Fix for iPad split view bug
[#173](https://github.com/alexaubry/BulletinBoard/pull/173)

## 🔖 v4.1.0
### New Features
- iOS 13 Dark Mode support
[#170](https://github.com/alexaubry/BulletinBoard/issues/170)
- Add mechanism to pop to item
[#165](https://github.com/alexaubry/BulletinBoard/pull/165)

### Fixes
- Remove testing dependencies from the Cartfile 
[#166](https://github.com/alexaubry/BulletinBoard/pull/166)

## 🔖 v4.0.0
### Fixes
- Upgrade to Swift 5

## 🔖 v3.0.0

### New Features

- Add  `isShowingBulletin` property
- Add `willDisplay` method to BLTNItem
- Add option to show the bulletin above the whole application

### Fixes

- Upgrade to Swift 4.2
- Fix frozen dismissal after initial interaction

## 🔖 v2.0.2

- Fix setters and retain semantics
- Add workaround to allow static library usage
- Fix Swift version in Podspec for compatibility with Xcode 10

## 🔖 v2.0.1

- Add missing resources to Podspec (this caused a crash)

## 🔖 v2.0.0

### New Features

- Make PageBulletinItem more open to customization: if you create custom pages, you no longer need to recreate the standard components yourself
- Customize fonts and more colors
- Customize status bar colors
- Customize bulletin background color
- Customize corner radius
- Customize padding between screen and bulletin
- Hide the activity indicator without changing the current item 
- Annotate library to support Objective-C apps
- Handle keyboard frame updates (support for text fields)
- Support for tinting images with template rendering mode
- Allow customization of the background view
- Add text field as a standard control
- Show activity indicator immediately after item is presented
- Callback for configuration and presentation from BulletinItem

### User-Facing Changes

- On iPad, the bulletin will be presented at the center of the screen and can only be dismissed by a tap (no swipe)
- The item will not be dismissed on swipe unless the user lifts their finger from the screen
- Use screen corner radius on iPhone X

### Bug fixes

- Fix dismiss tap background gesture being called for touches inside the content view
- Fix width contraint not being respected for regular layouts
- Fix iTunes Connect rejection bug due to LLVM code coverage
- Fix action button not being hidden when changing the item
- Fix dismissal handler not being called
- Fix controls inside the card not receiving `touchesEnded` events
- Fix cropped bulletin when presenting above split view controller
- Correctly reset non-dismissable cards position when swipe ends
- Fix Auto Layout conflicts during transitions
- Fix crash when reusing bulletin manager

### Library

- Split `BulletinInterfaceFactory` in two more open classes: `BulletinAppearance` for appearance customization, and `BulletinInterfaceBuilder` for interface components creation
- Create `ActionBulletinItem` as a root bulletin item for items with buttons. Handles button creation and tap events. Views above and below buttons are customizable
- Add example of a collection view bulletin item
- Remove `HighlightButton` from public API
- Various gardening operations to make comments and code more clear

## 🔖 v1.3.0

- Add customizable bulletin backgrounds
- Refactor swipe-to-dismiss: use animation controllers
- Add interactive dismissal (animated background blur radius / opacity)
- Improve iPhone X support: display a blurred bar at the bottom of the safe area to highlight the home indicator
- Simplify layout
- Various documentation and codebase improvements

## 🔖 v1.2.0

- Dismiss the bulletin by swiping down
- Support Swift 3.2

## 🔖 v1.1.0

- Add Accessibility technologies support (VoiceOver, Switch Control) - thanks @lennet!
- Add an optional activity indicator before transitions
- Improve memory management and fix retain cycles/leaks

## 🔖 v1.0.0

- Inital Release
