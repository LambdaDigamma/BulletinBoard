# iOS regression tests

Run the package tests with an installed iOS simulator:

```sh
Scripts/test-ios.sh -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' -enableThreadSanitizer YES
```

Use `xcrun simctl list devices available` to select a simulator on the current Mac. Repeat with a current iOS runtime. The Duo layout APIs require Xcode 27.1 or later. The original destructor validation used Xcode 27 RC, Swift 6.4, and both iOS 18.6 and iOS 27.1, with Thread Sanitizer.

The script creates a test workspace under the ignored `.build` directory. It tests the Swift package, not the legacy framework scheme that has the same name.

The lifetime tests check synchronous release from a main queue callback with task-local storage, release of animation blocks and captured views, controller release, and item teardown on MainActor. A background owner release must queue item teardown on MainActor and preserve caller task-local values. The manager must not escape from its destructor.

Before the fix, the animation phase test aborts on iOS 18.6 in `TaskLocal::StopLookupScope`, through `swift_task_deinitOnExecutorMainActorBackDeploy`. This matches [Swift issue 88036](https://github.com/swiftlang/swift/issues/88036). Explicit nonisolated destructors bypass that runtime path. UI methods retain MainActor isolation.

## Focused layout checks

```sh
Scripts/test-ios.sh -destination 'platform=iOS Simulator,name=iPhone 17e,OS=27.2' \
    -parallel-testing-enabled NO \
    -only-testing:BLTNBoardTests/BulletinLayoutRegionTests \
    -only-testing:BLTNBoardTests/BulletinViewControllerLayoutTests \
    -only-testing:BLTNBoardTests/BulletinSwipeScrollingTests
```

The region tests cover vertical and horizontal divisions, right-to-left layout, asymmetric bounds, stable region selection, and keyboard-reduced space. The UIKit tests use real windows and child trait overrides. They check narrow and short containers, long-content scrolling and expansion, safe-area changes, corner options, hidden-indicator content clearance, hidden-keyboard layout policy, and loaded-controller release. Swipe tests check that content drags scroll and that downward dismissal starts only at the top of a compact dismissable card.

Repeat the affected UIKit and lifetime tests on an older supported iOS runtime to check availability guards. Use the [Duo demo checks](../guides/Adaptive%20Layout.md) to verify live fold, keyboard, and nested gallery interactions. The Swift package test target does not build the demo targets, so gallery resizing is checked in the demo app.

## Native sheet checks

```sh
Scripts/test-ios-hosted.sh -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.2' \
    -parallel-testing-enabled NO \
    -only-testing:BLTNBoardTests/NativeSheetManagerTests \
    -only-testing:BLTNBoardTests/NativeSheetLayoutTests \
    -only-testing:BLTNBoardTests/BulletinViewControllerLayoutTests \
    -only-testing:BLTNBoardTests/BulletinSwipeScrollingTests \
    -only-testing:BLTNBoardTests/DeinitializationTests
```

Native manager tests check loading locks, startup spinner contrast across appearance changes, explicit spinner colors, unchanged field instances and values, push/pop callbacks and height changes, explicit and native dismissal cleanup, duplicate delegate callbacks, a visible viewport after reopening long content, scene presentation, overlay presentation, and callback re-entry. Layout tests check width changes, asymmetric safe areas, Dynamic Type, scrolling to a tappable final action, and controller release.

The hosted script generates a small scene-based app and test project under the ignored `.build/HostedTests` directory. It links the local Swift package and uses the same test sources. A standalone SwiftPM test process has no connected application scene, so it cannot verify a system sheet presentation. The hosted app provides that scene; the original script remains useful for layout, geometry, and lifetime tests.

Repeat the presenter-selection, shared layout, swipe, and lifetime tests on an older runtime. A `.nativeSheet` request must use the custom presenter before iOS 26. Tests that need the native presenter explicitly skip on older releases.

Use the demo mode selector for live Duo checks. Test the Book posture, a horizontal fold, the software keyboard, long content, and the photo gallery. Native trailing placement requires iOS 27; a tall native sheet can span the horizontal fold. The scroll test proves action reachability in a short viewport, while simulator interaction checks the actual system sheet placement.
