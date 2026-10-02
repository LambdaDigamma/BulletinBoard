#!/bin/bash
set -euo pipefail

package_root=$(cd "$(dirname "$0")/.." && pwd)
hosted_project="$package_root/.build/HostedTests/BulletinBoardTests.xcodeproj"

# System sheet presentation needs an application with a connected window scene.
# Generate that host in build output; keep the package and its tests authoritative.
python3 - "$package_root" "$hosted_project" <<'PYTHON'
from pathlib import Path
import plistlib
import sys

package_root = Path(sys.argv[1])
project = Path(sys.argv[2])
output = project.parent
host = output / 'Host'
host.mkdir(parents=True, exist_ok=True)
project.mkdir(parents=True, exist_ok=True)

(host / 'AppDelegate.swift').write_text('''import UIKit

@main
@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     configurationForConnecting session: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: session.role)
    }
}
''')
(host / 'SceneDelegate.swift').write_text('''import UIKit

@MainActor
final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        let controller = UIViewController()
        controller.view.backgroundColor = .systemBackground
        window.rootViewController = controller
        self.window = window
        window.makeKeyAndVisible()
    }
}
''')
orientations = ['UIInterfaceOrientationPortrait', 'UIInterfaceOrientationPortraitUpsideDown',
                'UIInterfaceOrientationLandscapeLeft', 'UIInterfaceOrientationLandscapeRight']
with (host / 'Info.plist').open('wb') as file:
    plistlib.dump({
        'CFBundleExecutable': '$(EXECUTABLE_NAME)',
        'CFBundleIdentifier': '$(PRODUCT_BUNDLE_IDENTIFIER)',
        'CFBundleName': '$(PRODUCT_NAME)',
        'CFBundlePackageType': 'APPL',
        'CFBundleShortVersionString': '1.0',
        'CFBundleVersion': '1',
        'LSRequiresIPhoneOS': True,
        'UILaunchScreen': {},
        'UISupportedInterfaceOrientations': orientations,
        'UISupportedInterfaceOrientations~ipad': orientations,
        'UIApplicationSceneManifest': {
            'UIApplicationSupportsMultipleScenes': True,
            'UISceneConfigurations': {'UIWindowSceneSessionRoleApplication': [{
                'UISceneConfigurationName': 'Default Configuration',
                'UISceneDelegateClassName': '$(PRODUCT_MODULE_NAME).SceneDelegate',
            }]},
        },
    }, file)

# Stable identifiers make the generated project easy to inspect.
(project / 'project.pbxproj').write_text('''// !$*UTF8*$!
{
    archiveVersion = 1;
    classes = {};
    objectVersion = 70;
    objects = {
        A10000000000000000000001 = {isa = PBXProject; buildConfigurationList = A10000000000000000000002; compatibilityVersion = "Xcode 16.0"; developmentRegion = en; knownRegions = (en, Base); mainGroup = A10000000000000000000003; productRefGroup = A10000000000000000000004; projectDirPath = ""; projectRoot = ""; packageReferences = (A10000000000000000000005); targets = (A10000000000000000000010, A10000000000000000000020); attributes = {BuildIndependentTargetsInParallel = YES;}; };
        A10000000000000000000002 = {isa = XCConfigurationList; buildConfigurations = (A10000000000000000000006); defaultConfigurationIsVisible = 0; defaultConfigurationName = Debug; };
        A10000000000000000000003 = {isa = PBXGroup; children = (A10000000000000000000007, A10000000000000000000008, A10000000000000000000004); sourceTree = "<group>"; };
        A10000000000000000000004 = {isa = PBXGroup; children = (A10000000000000000000011, A10000000000000000000021); name = Products; sourceTree = "<group>"; };
        A10000000000000000000005 = {isa = XCLocalSwiftPackageReference; relativePath = "../.."; };
        A10000000000000000000006 = {isa = XCBuildConfiguration; name = Debug; buildSettings = {SDKROOT = iphoneos; IPHONEOS_DEPLOYMENT_TARGET = 15.0; SWIFT_VERSION = 6.0; SWIFT_STRICT_CONCURRENCY = complete; SWIFT_APPROACHABLE_CONCURRENCY = YES; SWIFT_OPTIMIZATION_LEVEL = "-Onone"; ONLY_ACTIVE_ARCH = YES; ENABLE_TESTABILITY = YES; CLANG_ENABLE_MODULES = YES; TARGETED_DEVICE_FAMILY = "1,2"; }; };
        A10000000000000000000007 = {isa = PBXFileSystemSynchronizedRootGroup; path = Host; sourceTree = "<group>"; explicitFileTypes = {}; explicitFolders = (); exceptions = (A10000000000000000000009); };
        A10000000000000000000008 = {isa = PBXFileSystemSynchronizedRootGroup; path = "../../Tests/BLTNBoardTests"; sourceTree = "<group>"; explicitFileTypes = {}; explicitFolders = (); };
        A10000000000000000000009 = {isa = PBXFileSystemSynchronizedBuildFileExceptionSet; membershipExceptions = (Info.plist); target = A10000000000000000000010; };
        A10000000000000000000010 = {isa = PBXNativeTarget; name = BulletinTestHost; productName = BulletinTestHost; productType = "com.apple.product-type.application"; productReference = A10000000000000000000011; buildConfigurationList = A10000000000000000000012; buildPhases = (A10000000000000000000013, A10000000000000000000014, A10000000000000000000015); buildRules = (); dependencies = (); fileSystemSynchronizedGroups = (A10000000000000000000007); };
        A10000000000000000000011 = {isa = PBXFileReference; explicitFileType = wrapper.application; path = BulletinTestHost.app; sourceTree = BUILT_PRODUCTS_DIR; };
        A10000000000000000000012 = {isa = XCConfigurationList; buildConfigurations = (A10000000000000000000016); defaultConfigurationIsVisible = 0; defaultConfigurationName = Debug; };
        A10000000000000000000013 = {isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; };
        A10000000000000000000014 = {isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; };
        A10000000000000000000015 = {isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; };
        A10000000000000000000016 = {isa = XCBuildConfiguration; name = Debug; buildSettings = {PRODUCT_NAME = "$(TARGET_NAME)"; PRODUCT_BUNDLE_IDENTIFIER = com.BulletinBoard.NativeSheetTestHost; INFOPLIST_FILE = Host/Info.plist; SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor; LD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks"); }; };
        A10000000000000000000020 = {isa = PBXNativeTarget; name = BLTNBoardTests; productName = BLTNBoardTests; productType = "com.apple.product-type.bundle.unit-test"; productReference = A10000000000000000000021; buildConfigurationList = A10000000000000000000022; buildPhases = (A10000000000000000000023, A10000000000000000000024, A10000000000000000000025); buildRules = (); dependencies = (A10000000000000000000028); packageProductDependencies = (A10000000000000000000029); fileSystemSynchronizedGroups = (A10000000000000000000008); };
        A10000000000000000000021 = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; path = BLTNBoardTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };
        A10000000000000000000022 = {isa = XCConfigurationList; buildConfigurations = (A10000000000000000000026); defaultConfigurationIsVisible = 0; defaultConfigurationName = Debug; };
        A10000000000000000000023 = {isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; };
        A10000000000000000000024 = {isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (A10000000000000000000030); runOnlyForDeploymentPostprocessing = 0; };
        A10000000000000000000025 = {isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; };
        A10000000000000000000026 = {isa = XCBuildConfiguration; name = Debug; buildSettings = {PRODUCT_NAME = "$(TARGET_NAME)"; PRODUCT_BUNDLE_IDENTIFIER = com.BulletinBoard.NativeSheetTests; GENERATE_INFOPLIST_FILE = YES; TEST_HOST = "$(BUILT_PRODUCTS_DIR)/BulletinTestHost.app/BulletinTestHost"; BUNDLE_LOADER = "$(TEST_HOST)"; LD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks", "@loader_path/Frameworks"); }; };
        A10000000000000000000027 = {isa = PBXContainerItemProxy; containerPortal = A10000000000000000000001; proxyType = 1; remoteGlobalIDString = A10000000000000000000010; remoteInfo = BulletinTestHost; };
        A10000000000000000000028 = {isa = PBXTargetDependency; target = A10000000000000000000010; targetProxy = A10000000000000000000027; };
        A10000000000000000000029 = {isa = XCSwiftPackageProductDependency; package = A10000000000000000000005; productName = BLTNBoard; };
        A10000000000000000000030 = {isa = PBXBuildFile; productRef = A10000000000000000000029; };
    };
    rootObject = A10000000000000000000001;
}
''')
schemes = project / 'xcshareddata/xcschemes'
schemes.mkdir(parents=True, exist_ok=True)
(schemes / 'BulletinBoardTests.xcscheme').write_text('''<?xml version="1.0" encoding="UTF-8"?>
<Scheme version="1.7">
  <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
    <BuildActionEntries>
      <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="NO" buildForArchiving="NO" buildForAnalyzing="YES">
        <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="A10000000000000000000010" BuildableName="BulletinTestHost.app" BlueprintName="BulletinTestHost" ReferencedContainer="container:BulletinBoardTests.xcodeproj"/>
      </BuildActionEntry>
    </BuildActionEntries>
  </BuildAction>
  <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB">
    <Testables>
      <TestableReference skipped="NO">
        <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="A10000000000000000000020" BuildableName="BLTNBoardTests.xctest" BlueprintName="BLTNBoardTests" ReferencedContainer="container:BulletinBoardTests.xcodeproj"/>
      </TestableReference>
    </Testables>
  </TestAction>
</Scheme>
''')
PYTHON

xcodebuild -project "$hosted_project" -scheme BulletinBoardTests \
    CODE_SIGNING_ALLOWED=NO "$@" test
