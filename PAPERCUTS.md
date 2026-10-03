# Papercuts

Reviewed on 2026-10-03. Status below separates current source issues from historical environment observations. Build checks do not confirm live preview or fold behavior.

## Favorite pets use two storage keys

Status: open. The source still uses both keys.

Impact: the gallery can show the saved animal type while a newly opened pet selector selects Cats.

Reproduce in the demo: select Dogs, continue to the gallery, dismiss the bulletin, then reopen **Bulletins > Favorite Pets**. The feed keeps Dogs, but the selector reads its default Cats value.

`Example/Swift/Bulletin/BulletinDataSource.swift` stores `PetBoardFavoriteTabIndex`. `Example/CustomBulletins/CollectionUtilities.swift` reads and writes `BLTNBoard.FavoriteTabIndex`. Use one key and migrate the stored value. This is outside the Duo layout change.

The native demo check also reproduced this through **Dogs > Change > Cats > Validate**: the gallery changed to Cats, but the feed returned to Dogs. Test this full path when the storage keys are unified.

## Xcode 27.1 beta Intel simulator linker warning

Status: not reproduced after the project update. The Debug generic simulator build succeeds for arm64 and x86_64 with no ambiguous-target linker warning. The Intel simulator runtime was not tested.

Original impact: a generic simulator build succeeded but reported an ambiguous target atom while linking the x86_64 Swift package framework. The arm64 Duo demo ran; the Intel simulator runtime was not checked.

Reproduce with `xcodebuild -workspace BulletinBoard.xcworkspace -scheme BB-Swift -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` on Xcode 27.1 beta. The linker reports `address=0x63EB3 points before section(31) start and the target atom is ambiguous` in `BLTNBoarddynamic-product`. Keep the original diagnostic for comparison if the warning returns. No linker setting was changed to suppress it.

## Simulator service responds intermittently on 2026-10-03

Status: recovered for the installed iOS 18.6 and 27.2 test destinations. Recent focused hosted tests complete in seconds. Keep this record for diagnosis if the issue returns.

Impact: native sheet visual checks can fail to connect, and focused runtime tests can start after a long delay. Generic simulator builds still pass. The focused native test retry eventually completed with 15 passing tests after about 11 minutes.

Observed reproduction: `xcrun simctl list devices available` did not return promptly, but eventually listed booted devices. Xcode initially reported only **Any iOS Simulator Device**, with no usable simulator destinations. Device Hub listed Duo but its Appearance inspector stayed busy and app accessibility content was unavailable. Two bounded nonworkspace DeviceInteraction sessions could not connect.

If the issue returns, restore simulator service access before checking the native sheet over photos in light and dark mode. Do not restart shared simulator services without accounting for other running simulator apps. No global service or device settings were changed during this check.

The later check could connect to iPhone 18 Pro on iOS 27.2. Duo/iOS 27.1 was absent from DeviceInteraction's eligible devices, and Device Hub showed Start with disabled controls. The Duo was not started or changed.

## Objective-C module verification cannot import the Swift package

Status: fixed in the project update. Fresh Debug and Release arm64 demo builds pass. The generic Debug build also passes for arm64 and x86_64. The products contain the Swift module and no Clang module or public generated Objective-C header.

Impact before the fix: enabling `ENABLE_MODULE_VERIFIER = YES` for `CustomBulletins` made the demo build fail. Its generated `CustomBulletins-Swift.h` contains `@import BLTNBoard`, but the Swift package has no matching Clang module. The review reproduced `module 'BLTNBoard' not found` in a fresh arm64 simulator build.

The demo has Swift clients only. `CustomBulletins` now exports its Swift module without a Clang module (`DEFINES_MODULE = NO`) or public generated Objective-C header (`SWIFT_INSTALL_OBJC_HEADER = NO`). Its Clang module verifier stays disabled. The standalone `BLTNBoard` framework keeps module verification enabled. See [Apple's build settings reference](https://developer.apple.com/documentation/xcode/build-settings-reference) for the generated-header setting.

## iOS 27.1 runtime is listed but cannot boot Duo

Status: needs a boot check with a valid runtime. The review still sees iOS 27.1 build 24A94401 listed as available. That metadata does not prove that it can boot. No boot, reinstall, or runtime replacement was attempted during this review.

Impact at the last boot check: the Duo simulator could not start, so final fold checks remain pending. On 2026-10-03, CoreSimulator listed iOS 27.1 build 24A94401 as Ready and its mounted bundle existed, but `simctl boot 437E9AC5-3FCD-4E83-ABAB-102A12698D4C` failed with SimError401, “runtime path not found”. The runtime signature check failed with error -67054, “a sealed resource is missing or invalid”.

A targeted runtime unmount and scan-and-mount completed but did not fix boot. The Duo stayed shut down; no simulator data was erased and no shared service was restarted. Xcode could not download either the arm64-only or universal iOS 27.1 runtime. Obtain a valid compatible runtime installer before replacing the existing runtime.

## Xcode UIKit live preview reports presentation without showing the modal

Status: needs a live check with the current native-only fixtures. The older Native/Custom preview variants referenced below have been replaced.

Impact at the last live check: Close and form interaction checks were unavailable even when RenderPreview built successfully. On Xcode 27.1 / iPhone 18 Pro iOS 27.2, the host callback reported “Presented: Your name”, but the Live canvas showed only the striped host. The static native dark render showed the complete modal.

Historical reproduction before the native-only migration: open `Sources/Previews/FrameworkBulletinPreviews.swift`, render Native Form Dark, switch to Custom Form Dark, and select Live. The final check reproduced a host-only canvas in both variants. The computer-use server also reports `noWindowsAvailable` for pointer input. Check the preview presentation lifecycle and Xcode canvas session before relying on Live interaction validation. No runtime data or shared simulator services were changed. For the current check, use **Form - Dark**, select Live, and press **Show Bulletin**. Compare the visible modal with the host status.

## Framework preview lookup in the demo workspace

Status: needs a render-tool check after the synchronized-folder project update. The framework build confirms that its preview source is included; it does not confirm the tool can locate that source in the open demo workspace.

Impact at the last tool check: Xcode's render tool could not find the framework preview file from the open demo workspace. A static or Live tool check needed the package or framework project to be open.

Reproduction (2026-10-03): with only `BulletinBoard.xcworkspace` open, scheme `BB-Swift`, and the current iPhone Duo run active, request preview index 0 for `Sources/Previews/FrameworkBulletinPreviews.swift`. The tool returns `FileNotFoundError: File not found in project structure`. Open the package or framework project and retry the Page Size Transitions preview. The existing app run and destination were preserved.
