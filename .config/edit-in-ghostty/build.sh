#!/bin/bash
# Builds/rebuilds "Edit in Ghostty.app", the Finder default-editor droplet
# (see edit-in-ghostty.applescript in this directory), and applies the duti
# file-association config that points Finder at it. Safe to re-run.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="/Applications/Edit in Ghostty.app"
BUNDLE_ID="com.mheindel.edit-in-ghostty"
PLIST="$APP/Contents/Info.plist"

rm -rf "$APP"
osacompile -o "$APP" "$SCRIPT_DIR/edit-in-ghostty.applescript"

/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $BUNDLE_ID" "$PLIST"

# osacompile's default CFBundleDocumentTypes is a "*"/Viewer wildcard entry;
# replace it with real UTIs/extensions so `duti` can assign this app as the
# default handler for them (duti otherwise fails against undeclared types).
/usr/libexec/PlistBuddy -c "Delete :CFBundleDocumentTypes" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes array" "$PLIST"

/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0 dict" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:CFBundleTypeRole string Editor" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes array" "$PLIST"
i=0
for uti in public.plain-text public.source-code net.daringfireball.markdown \
           public.json public.xml public.comma-separated-values-text; do
  /usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes:$i string $uti" "$PLIST"
  i=$((i + 1))
done

/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:1 dict" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:1:CFBundleTypeRole string Editor" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:1:CFBundleTypeExtensions array" "$PLIST"
i=0
for ext in yml yaml toml ini conf env log sql graphql proto tf \
           ts tsx js jsx mjs cjs py pyi go rb java c cpp h hpp rs swift \
           css scss vue sh zsh bash; do
  /usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:1:CFBundleTypeExtensions:$i string $ext" "$PLIST"
  i=$((i + 1))
done

# osacompile's ad-hoc signature doesn't cover our post-hoc Info.plist edits
# (`codesign -dv` would show "Info.plist=not bound"); an app in that state
# silently fails Apple Events instead of prompting for Automation permission.
# Re-signing fixes it.
codesign --force --deep -s - "$APP"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"

duti "$SCRIPT_DIR/../duti/default-editor.duti"
duti "$SCRIPT_DIR/../duti/ghostty-terminal.duti"
duti "$SCRIPT_DIR/../duti/document-apps.duti"

echo "Built and registered: $APP"
echo "First launch will prompt for permission to control Ghostty — approve it."
