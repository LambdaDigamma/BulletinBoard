#!/bin/bash
set -euo pipefail

package_root=$(cd "$(dirname "$0")/.." && pwd)
validation_workspace="$package_root/.build/Tests.xcworkspace"

# The legacy framework project has the same scheme name as the Swift package.
# Use an explicit package test scheme so Xcode discovers the SwiftPM test target.
python3 - "$package_root" "$validation_workspace" <<'PYTHON'
from pathlib import Path
from xml.sax.saxutils import escape
import sys

package_root = escape(sys.argv[1], {'"': '&quot;'})
workspace = Path(sys.argv[2])
workspace.mkdir(parents=True, exist_ok=True)
workspace.joinpath('contents.xcworkspacedata').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Workspace version="1.0">
  <FileRef location="absolute:{package_root}"/>
</Workspace>
''')
scheme = workspace / 'xcshareddata/xcschemes/BulletinBoardTests.xcscheme'
scheme.parent.mkdir(parents=True, exist_ok=True)
scheme.write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme version="1.7">
  <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
    <BuildActionEntries>
      <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="NO" buildForArchiving="NO" buildForAnalyzing="YES">
        <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="BLTNBoard" BuildableName="BLTNBoard" BlueprintName="BLTNBoard" ReferencedContainer="container:{package_root}"/>
      </BuildActionEntry>
    </BuildActionEntries>
  </BuildAction>
  <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB">
    <Testables>
      <TestableReference skipped="NO">
        <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="BLTNBoardTests" BuildableName="BLTNBoardTests" BlueprintName="BLTNBoardTests" ReferencedContainer="container:{package_root}"/>
      </TestableReference>
    </Testables>
  </TestAction>
</Scheme>
''')
PYTHON

xcodebuild -workspace "$validation_workspace" -scheme BulletinBoardTests \
    CODE_SIGNING_ALLOWED=NO "$@" test
