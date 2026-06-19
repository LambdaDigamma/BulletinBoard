# BulletinBoard

[![Documentation](https://img.shields.io/badge/Documentation-available-blue.svg)](https://alexisakers.github.io/BulletinBoard)
[![Contact: @_alexaubry](https://raw.githubusercontent.com/alexaubry/BulletinBoard/main/.assets/twitter_badge.svg?sanitize=true)](https://twitter.com/_alexaubry)

BulletinBoard is an iOS library that generates and manages contextual cards displayed at the bottom of the screen. It is especially well suited for quick user interactions such as onboarding screens or configuration.

It has an interface similar to the cards displayed by iOS for AirPods, Apple TV/HomePod configuration and NFC tag scanning. It supports both the iPhone, iPhone X and the iPad.

It has built-in support for accessibility features such as VoiceOver and Switch Control.

Here are some screenshots showing what you can build with BulletinBoard:

![Demo Screenshots](https://raw.githubusercontent.com/alexaubry/BulletinBoard/main/.assets/demo_screenshots.png)

## Requirements

- Xcode 26 and later
- iOS 15 and later
- Swift 6 language mode with SwiftPM PackageDescription 6.2 or later.

## Demo

A demo project is included in the `BulletinBoard` workspace. It demonstrates how to:

- integrate the library (setup, data flow)
- create standard page cards
- create custom page subclasses to add features
- create custom cards from scratch

Build and run the `BB-Swift` scheme to open the demo app.

## Installation

To install BulletinBoard using the [Swift Package Manager](https://swift.org/package-manager/), add this dependency to your `Package.swift` file:

~~~swift
.package(url: "https://github.com/alexaubry/BulletinBoard.git", from: "6.1.0")
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
