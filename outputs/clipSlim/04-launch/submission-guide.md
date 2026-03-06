# Submission Guide - ClipSlim

**Version:** 1.0.0 (Build 1)
**Platform:** macOS 14.0+ (Sonoma)
**Distribution:** Direct (DMG) + Mac App Store

---

## Part 1: Direct Distribution (Notarized DMG)

This is the primary distribution method for launch weekend. ClipSlim already has a working notarization pipeline per the README.

### Step 1: Build Release Binary

```bash
cd /Users/berkerceylan/Documents/GitHub/clipSlim

# Run tests first
xcodebuild -project ClipSlim.xcodeproj \
  -scheme ClipSlim \
  -destination 'platform=macOS' \
  test

# Build release
xcodebuild -project ClipSlim.xcodeproj \
  -scheme ClipSlim \
  -configuration Release \
  build
```

Locate the built app:
```bash
# Default location (may vary based on Xcode settings)
find ~/Library/Developer/Xcode/DerivedData/ClipSlim-* \
  -name "ClipSlim.app" -path "*/Release/*" \
  -maxdepth 5
```

### Step 2: Code Sign the App

```bash
codesign --force --deep --options runtime --timestamp \
  --sign "Developer ID Application: <Your Name> (<TEAMID>)" \
  /path/to/ClipSlim.app
```

Verify signing:
```bash
codesign -dv --verbose=4 /path/to/ClipSlim.app
```

### Step 3: Create the DMG

```bash
cd /Users/berkerceylan/Documents/GitHub/clipSlim
./scripts/create_stylized_dmg.sh /path/to/ClipSlim.app
```

### Step 4: Sign the DMG

```bash
codesign --force --options runtime --timestamp \
  --sign "Developer ID Application: <Your Name> (<TEAMID>)" \
  /path/to/ClipSlim.dmg
```

### Step 5: Notarize

The keychain profile `clipslim-notary` is already configured per the README.

```bash
# Submit for notarization (usually takes 2-10 minutes)
xcrun notarytool submit /path/to/ClipSlim.dmg \
  --keychain-profile clipslim-notary \
  --wait

# Staple the ticket
xcrun stapler staple /path/to/ClipSlim.dmg
```

If notarization fails, check the log:
```bash
xcrun notarytool log <submission-id> \
  --keychain-profile clipslim-notary
```

### Step 6: Verify Gatekeeper

```bash
# Verify the app
spctl --assess --type execute -vv /path/to/ClipSlim.app

# Expected output should include: source=Notarized Developer ID
```

### Step 7: Final Smoke Test

```bash
# Mount the DMG
hdiutil attach /path/to/ClipSlim.dmg

# Copy to a temporary location (simulating user install)
cp -R /Volumes/ClipSlim/ClipSlim.app /tmp/ClipSlimTest.app

# Launch it
open /tmp/ClipSlimTest.app

# After testing, clean up
rm -rf /tmp/ClipSlimTest.app
hdiutil detach /Volumes/ClipSlim
```

Manual smoke test checklist:
- App appears in menubar
- Onboarding flow works (if first launch)
- Copy an image to clipboard -- optimization happens
- Check overlay shows compression stats
- Test Option+1 and Option+2 hotkeys
- Enable folder watcher, drop an image in the folder
- Quit and relaunch -- settings persist

### Step 8: Upload to Website

- Upload the notarized DMG to your hosting
- Update the download link on the landing page
- Test the download link in a browser
- Verify the downloaded file matches (checksum optional but recommended):

```bash
shasum -a 256 /path/to/ClipSlim.dmg
```

---

## Part 2: Mac App Store Submission

### Prerequisites

The Mac App Store requires additional steps compared to direct distribution.

**Key Difference: Sandbox Requirement**

The Mac App Store requires all apps to be sandboxed. ClipSlim currently has empty entitlements. You must add sandbox entitlements before submitting.

### Step 1: Add Sandbox Entitlements

Edit `ClipSlim/Resources/ClipSlim.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
</dict>
</plist>
```

Notes on sandbox and ClipSlim functionality:
- **Clipboard access:** Works inside sandbox on macOS (NSPasteboard is accessible)
- **Folder watcher:** Requires `com.apple.security.files.user-selected.read-write` so the user can select a folder via an open panel, and ClipSlim can then watch it
- **Global hotkeys:** May require accessibility permission. Test thoroughly.
- **Notifications:** Should work under sandbox

**IMPORTANT:** Test all core functionality under sandbox before submitting. Clipboard polling and folder watching are the highest-risk features.

### Step 2: Configure Signing for Mac App Store

In Xcode:
1. Select the ClipSlim target
2. Go to Signing & Capabilities
3. Change signing to "Apple Distribution" (not Developer ID)
4. Ensure "Automatically manage signing" is checked (or manually select the correct provisioning profile)
5. Team must match your App Store Connect team

### Step 3: Archive and Upload

**Option A: Via Xcode (Recommended)**
1. Product > Archive
2. Wait for archive to complete
3. In Organizer window, select the archive
4. Click "Distribute App"
5. Select "App Store Connect"
6. Select "Upload"
7. Follow prompts (signing, entitlements review)
8. Wait for upload to complete

**Option B: Via Command Line**
```bash
# Archive
xcodebuild -project ClipSlim.xcodeproj \
  -scheme ClipSlim \
  -configuration Release \
  -archivePath /tmp/ClipSlim.xcarchive \
  archive

# Export for App Store
xcodebuild -exportArchive \
  -archivePath /tmp/ClipSlim.xcarchive \
  -exportPath /tmp/ClipSlimExport \
  -exportOptionsPlist ExportOptions.plist
```

You will need an `ExportOptions.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
```

### Step 4: Configure in App Store Connect

After the build processes (usually 15-30 minutes):

1. Go to App Store Connect > Your App > macOS section
2. Under "Build," click the + button and select your uploaded build
3. Fill in all metadata fields (see prelaunch-checklist.md Phase 2)
4. Upload screenshots
5. Complete App Review Information:
   - Notes: "ClipSlim is a menubar utility. After launching, it appears as an icon in the macOS menubar. To test: (1) Launch the app, (2) Copy any image to your clipboard (e.g., screenshot with Cmd+Shift+4), (3) The app will automatically optimize the image and show stats in the menubar popover."
   - Contact info for reviewer
6. Complete age rating (4+)
7. Complete pricing

### Step 5: Submit for Review

1. Click "Add for Review"
2. Review all information one final time
3. Click "Submit to App Review"

**Expected review timeline:**
- Initial submission: 1-3 business days (sometimes faster)
- Weekend submissions may not be reviewed until Monday
- You will receive an email when status changes

### Step 6: Post-Submission Monitoring

Check App Store Connect daily for:
- **Waiting for Review** -- normal, just wait
- **In Review** -- reviewer is looking at it now
- **Approved** -- celebrate, it will go live shortly
- **Rejected** -- read the rejection reason carefully, fix, resubmit

Common rejection reasons for menubar utilities:
- Insufficient functionality (too simple) -- unlikely for ClipSlim
- Missing sandbox entitlements -- addressed above
- Menubar-only apps need clear review instructions -- addressed in notes
- Privacy policy missing or inaccessible -- addressed in checklist

---

## Part 3: Post-Submission Checklist

### For Both Distribution Methods
- [ ] Verify app version string is 1.0.0 everywhere (Info.plist, App Store Connect)
- [ ] Verify bundle ID matches across Xcode, App Store Connect, and signing
- [ ] Verify app icon displays correctly in both stores and on macOS dock/Launchpad
- [ ] Test auto-update mechanism (for DMG: document how users update manually)

### DMG Update Process (for future versions)
1. Build new release
2. Sign, create DMG, sign DMG
3. Notarize and staple
4. Upload to website, replacing old DMG
5. Update version number on website
6. Announce update via social media

### MAS Update Process (for future versions)
1. Increment version in Info.plist (e.g., 1.1.0)
2. Increment build number (e.g., 2)
3. Archive and upload via Xcode
4. In App Store Connect: create new version, add build, fill "What's New"
5. Submit for review
6. Typical update review: same day to 1-2 days

---

## Quick Reference: Key Commands

```bash
# Full DMG build pipeline (after initial setup)
xcodebuild -project ClipSlim.xcodeproj -scheme ClipSlim -configuration Release build && \
codesign --force --deep --options runtime --timestamp \
  --sign "Developer ID Application: <NAME> (<TEAMID>)" /path/to/ClipSlim.app && \
./scripts/create_stylized_dmg.sh /path/to/ClipSlim.app && \
codesign --force --options runtime --timestamp \
  --sign "Developer ID Application: <NAME> (<TEAMID>)" /path/to/ClipSlim.dmg && \
xcrun notarytool submit /path/to/ClipSlim.dmg --keychain-profile clipslim-notary --wait && \
xcrun stapler staple /path/to/ClipSlim.dmg && \
spctl --assess --type execute -vv /path/to/ClipSlim.app
```

```bash
# Check notarization status for a previous submission
xcrun notarytool history --keychain-profile clipslim-notary
```

```bash
# Verify stapling
xcrun stapler validate /path/to/ClipSlim.dmg
```
