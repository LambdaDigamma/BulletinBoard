# BulletinBoard

[![Documentation](https://img.shields.io/badge/Documentation-available-blue.svg)](https://alexisakers.github.io/BulletinBoard)
[![Contact: @_alexaubry](https://raw.githubusercontent.com/alexaubry/BulletinBoard/main/.assets/twitter_badge.svg?sanitize=true)](https://twitter.com/_alexaubry)

BulletinBoard is an iOS library that generates and manages contextual cards displayed at the bottom of the screen. It is especially well suited for quick user interactions such as onboarding screens or configuration.

It has an interface similar to the cards displayed by iOS for AirPods, Apple TV/HomePod configuration and NFC tag scanning. It supports iPhone, iPhone Duo, and iPad.

It has built-in support for accessibility features such as VoiceOver and Switch Control.

Here are some screenshots showing what you can build with BulletinBoard:

![Demo Screenshots](https://raw.githubusercontent.com/alexaubry/BulletinBoard/main/.assets/demo_screenshots.png)

## Requirements

- Xcode 27.1 and later (the iOS 27.1 SDK supplies the iPhone Duo layout APIs)
- iOS 17 and later
- Swift 6 language mode with SwiftPM PackageDescription 6.2 or later.

## Demo

A demo project is included in the `BulletinBoard` workspace. It demonstrates how to:

- integrate the library (setup, data flow)
- create standard page cards
- create custom page subclasses to add features
- create custom cards from scratch

Build and run the `BB-Swift` scheme to open the demo app.

Use the **Bulletins** menu to select **Custom Card** or **Native Sheet**, then open the introduction, name form, date picker, pet selector, photo gallery, or long Pet Care Guide. Native sheets require iOS 26 or later. Both image galleries update their cell sizes when the available width changes. UIKit previews cover both presenters, narrow cards, and short windows.

## Framework previews

Open `Sources/Previews/FrameworkBulletinPreviews.swift` with the `BLTNBoard` scheme selected. Show the Xcode canvas and enable Live mode to use the bulletin buttons. These previews belong to the framework and Swift package; they do not need the demo app.

The previews cover alerts, dismissal and reopening, a text field, loading, push/pop, long content, large text, right-to-left layout, and native sheets in light and dark mode. See [Framework previews](guides/Framework%20Previews.md) for the check steps and runtime limits.

## Resizing and iPhone Duo

Custom cards adapt to the current view bounds and safe area. On iOS 27.1, a partially folded Duo places the whole custom card in one clear region beside the fold. Long content scrolls inside the card. Keyboard placement uses the local keyboard layout guide and the current item's keyboard policy.

You can also use a native UIKit sheet on iOS 26 or later:

```swift
let manager = BLTNItemManager(rootItem: item)
manager.presentationStyle = .nativeSheet
manager.showBulletin(above: self)
```

The default remains `.custom`. A native-sheet request falls back to the custom card on older releases. Native mode uses one content-height stop, scrolling, and system keyboard behavior. On iOS 26.1 and later, its solid system background adapts to light and dark mode. On iOS 26.0, UIKit can retain its glass sheet surface. On iOS 27 or later, it requests trailing placement for the Book posture. Tall native sheets can span a horizontal fold.

See [Adaptive layout](guides/Adaptive%20Layout.md) for placement rules, customization, and validation.

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
