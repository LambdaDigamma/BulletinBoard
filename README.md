# BulletinBoard

[![Documentation](https://img.shields.io/badge/Documentation-available-blue.svg)](https://alexisakers.github.io/BulletinBoard)
[![Contact: @_alexaubry](https://raw.githubusercontent.com/alexaubry/BulletinBoard/main/.assets/twitter_badge.svg?sanitize=true)](https://twitter.com/_alexaubry)

BulletinBoard is an iOS library that generates and manages contextual cards displayed at the bottom of the screen. It is especially well suited for quick user interactions such as onboarding screens or configuration.

It has an interface similar to the cards displayed by iOS for AirPods, Apple TV/HomePod configuration and NFC tag scanning. It supports iPhone, iPhone Duo, and iPad.

It has built-in support for accessibility features such as VoiceOver and Switch Control.

Here are some screenshots showing what you can build with BulletinBoard:

![Demo Screenshots](https://raw.githubusercontent.com/alexaubry/BulletinBoard/main/.assets/demo_screenshots.png)

## Requirements

- Xcode 27.1 and later
- iOS 17 and later
- Swift 6 language mode with SwiftPM PackageDescription 6.2 or later.

## Demo

A demo project is included in the `BulletinBoard` workspace. It demonstrates how to:

- integrate the library (setup, data flow)
- create standard page cards
- create custom page subclasses to add features
- create custom cards from scratch

Build and run the `BB-Swift` scheme to open the demo app.

Use the **Bulletins** menu to open the introduction, name form, date picker, pet selector, photo gallery, or long Pet Care Guide. All examples use native sheets on iOS 17 and later. Both image galleries update their cell sizes when the available width changes. UIKit previews cover narrow and short windows, dark mode, loading, and page transitions.

## Framework previews

Open `Sources/Previews/FrameworkBulletinPreviews.swift` with the `BLTNBoard` scheme selected. Show the Xcode canvas and enable Live mode to use the bulletin buttons. These previews belong to the framework and Swift package; they do not need the demo app.

The previews cover alerts, dismissal and reopening, a text field, loading, push/pop, long content, large text, right-to-left layout, and native sheets in light and dark mode. See [Framework previews](guides/Framework%20Previews.md) for the check steps and runtime limits.

## Resizing and iPhone Duo

BulletinBoard uses native UIKit sheets on every supported iOS release. Each sheet has one content-height stop. Long content scrolls, and UIKit handles keyboard movement. Page changes fade out the old content, animate the sheet height, and fade in the new content. Reduce Motion applies the new page without animation.

```swift
let manager = BLTNItemManager(rootItem: item)
manager.showBulletin(above: self)
```

The content background adapts to light and dark mode. On iOS 26.1 and later, the sheet also replaces the system glass surface with a solid background. UIKit uses automatic placement: a floating sheet centers in a flat window and moves away from an active fold. UIKit chooses the side. Floating sheets without a Close header keep matching 32-point top and bottom content gaps. The bottom safe area supplies that clearance first. Tall native sheets can span a horizontal fold; content and actions remain scrollable.

The custom presenter was removed. `presentationStyle`, `backgroundColor`, `backgroundViewStyle`, `edgeSpacing`, `cardCornerRadius`, and `shouldRespondToKeyboardChanges` remain as deprecated compatibility settings and have no effect. UIKit controls sheet appearance and placement. See [Adaptive layout](guides/Adaptive%20Layout.md) for behavior, migration details, and validation.

## Installation

To install BulletinBoard using the [Swift Package Manager](https://swift.org/package-manager/), add this dependency to your `Package.swift` file:

~~~swift
.package(url: "https://github.com/LambdaDigamma/BulletinBoard.git", from: "6.1.1")
~~~

## Documentation

- The full library documentation is available [here](https://alexisakers.github.io/BulletinBoard).
- To learn how to start using `BulletinBoard`, check out our [Getting Started](https://alexisakers.github.io/BulletinBoard/getting-started.html) guide.

## Contributing

Thank you for your interest in the project! Contributions are welcome and appreciated.

Make sure to read these guides before getting started:

- [Code of Conduct](https://github.com/alexaubry/BulletinBoard/blob/master/CODE_OF_CONDUCT.md)
- [Contribution Guidelines](https://github.com/alexaubry/BulletinBoard/blob/master/CONTRIBUTING.md)

## Author

Written by Alexis Aubry. You can [find me on Twitter](https://twitter.com/_alexaubry).

## License

BulletinBoard is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
