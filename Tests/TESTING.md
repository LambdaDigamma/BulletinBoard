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

Use `-only-testing:BLTNBoardTests/NativeSheetLayoutTests` with either script to check width changes, asymmetric safe areas, Dynamic Type, the fixed Close header, long-content scrolling, minimum total bottom clearance across zero, small, and large bottom insets, final-action hit testing, and controller release. Repeat affected tests on an older installed runtime. Use the [Duo demo checks](../guides/Adaptive%20Layout.md) for real fold, keyboard, and gallery interactions. Package tests do not build the demo targets.

## Framework preview fixture check

Use `-only-testing:BLTNBoardTests/BulletinCloseButtonTests` for system close-item appearance checks. `NativeSheetLayoutTests` also checks the fixed close header with long content, asymmetric safe areas, and right-to-left layout.

Run `Scripts/test-ios.sh` with `-only-testing:BLTNBoardTests/FrameworkPreviewTests` to check that an edited name survives preview form teardown and view creation. Use the [framework preview steps](../guides/Framework%20Previews.md) for live alert, loading, navigation, dismissal, and scrolling checks. These fixtures are debug-only and do not depend on the demo app.

Run `Scripts/test-ios-hosted.sh` with `SWIFT_ACTIVE_COMPILATION_CONDITIONS=DEBUG` and the same test filter to also check that explicit preview traits reach a bulletin presented outside the host controller's hierarchy. This check needs an application scene and skips in the standalone package test process.

## Native sheet checks

```sh
Scripts/test-ios-hosted.sh -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.2' \
    SWIFT_ACTIVE_COMPILATION_CONDITIONS=DEBUG -parallel-testing-enabled NO \
    -only-testing:BLTNBoardTests/NativeSheetManagerTests \
    -only-testing:BLTNBoardTests/NativeSheetLayoutTests \
    -only-testing:BLTNBoardTests/BulletinCloseButtonTests \
    -only-testing:BLTNBoardTests/FrameworkPreviewTests \
    -only-testing:BLTNBoardTests/DeinitializationTests
```

Native manager tests check loading locks, startup spinner contrast across appearance changes, explicit spinner colors, unchanged field instances and values, push/pop callbacks and height changes, explicit and native dismissal cleanup, duplicate delegate callbacks, a visible viewport after reopening long content, scene presentation, overlay presentation, and callback re-entry. A short-page test compares automatic scroll insets with a frame pinned to the bottom safe-area guide and confirms the same final-button position. Layout checks verify padding changes during deferred page layout and loading. Run `testFloatingSheetRetainsMinimumBottomClearance` on a regular-width iPad simulator to verify 12-point clearance when the actual floating sheet has no bottom inset; this test skips in compact width. Transition tests also sample the presented layer during growth and shrinkage to confirm intermediate heights and content opacity. They check rapid push cancellation, loading during both fade phases, dismissal during a fade, callback re-entry, and the immediate path when UIView animations are disabled. Layout tests check width changes, asymmetric safe areas, Dynamic Type, scrolling to a tappable final action, and controller release.

The hosted script generates a small scene-based app and test project under the ignored `.build/HostedTests` directory. It links the local Swift package and uses the same test sources. A standalone SwiftPM test process has no connected application scene, so it cannot verify a system sheet presentation. The hosted app provides that scene; the original script remains useful for layout, geometry, and lifetime tests.

Repeat these focused tests on an older runtime. Every supported release uses the native presenter; there is no custom fallback.

Use the framework Page Size Transitions preview and demo for visual checks. Sampled intermediate heights prove runtime sheet movement; they do not prove visual quality, Reduce Motion settings, software-keyboard behavior, or fold placement. Check these separately. Native trailing placement requires iOS 27; a tall native sheet can span a horizontal fold.
