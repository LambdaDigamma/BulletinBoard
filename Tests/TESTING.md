# iOS regression tests

Run the package tests with an installed iOS simulator:

```sh
Scripts/test-ios.sh -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' -enableThreadSanitizer YES
```

Use `xcrun simctl list devices available` to select a simulator on the current Mac. Repeat with a current iOS runtime. Use Xcode 26.3 for the CI compatibility check. Local validation used Xcode 27 RC, Swift 6.4, and both iOS 18.6 and iOS 27.1, with Thread Sanitizer.

The script creates a test workspace under the ignored `.build` directory. It tests the Swift package, not the legacy framework scheme that has the same name.

The tests check synchronous release from a main queue callback with task-local storage, release of animation blocks and captured views, keyboard observer owner destruction, and item teardown on MainActor. A background owner release must queue item teardown on MainActor and preserve caller task-local values. The manager must not escape from its destructor.

Before the fix, the animation phase test aborts on iOS 18.6 in `TaskLocal::StopLookupScope`, through `swift_task_deinitOnExecutorMainActorBackDeploy`. This matches [Swift issue 88036](https://github.com/swiftlang/swift/issues/88036). Explicit nonisolated destructors bypass that runtime path. UI methods retain MainActor isolation.
