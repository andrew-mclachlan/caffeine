# Building Caffeine

Caffeine builds as a universal app (arm64 and x86_64) for macOS 26 or later.
All commands are run from the top-level project folder.

## Requirements

- macOS 26 or later
- Xcode 27 (or any Xcode whose SDK supports macOS 26)
- For distribution: an Apple Developer Program membership

## 1. Local build (no Apple Developer account needed)

The project signs ad-hoc by default, which is enough to run the app on the Mac that built it.

```bash
xcodebuild -project Caffeine.xcodeproj -target Caffeine -configuration Release \
  SYMROOT="$PWD/build" build
```

The app is created at `build/Release/Caffeine.app`. Copy it to `/Applications` to install it.

Other Macs will refuse to open an ad-hoc signed app that was downloaded. For sharing, sign and notarize it (steps 2 to 4).

To check the architectures:

```bash
lipo -archs build/Release/Caffeine.app/Contents/MacOS/Caffeine   # x86_64 arm64
```

## 2. One-time setup for signing and notarizing

1. Join the Apple Developer Program.
2. Create a **Developer ID Application** certificate (Xcode → Settings → Accounts → Manage Certificates → +).
3. Confirm it is in your keychain and note its exact name:

   ```bash
   security find-identity -v -p codesigning
   ```

   It looks like `Developer ID Application: Your Name (TEAMID)`.

4. Create an app-specific password at appleid.apple.com (Sign-In and Security → App-Specific Passwords).
5. Store notarization credentials in the keychain. This prompts for the app-specific password:

   ```bash
   xcrun notarytool store-credentials caffeine-notary \
     --apple-id YOUR_APPLE_ID --team-id YOUR_TEAMID
   ```

The bundle identifier is `com.lightheadsw.caffeine` (set in `Info.plist` and the project). If you fork the project, change it to an identifier you own.

## 3. Signed release build

Replace the identity and team ID with your own:

```bash
xcodebuild -project Caffeine.xcodeproj -target Caffeine -configuration Release \
  SYMROOT="$PWD/build" clean build \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM=YOUR_TEAMID \
  "CODE_SIGN_IDENTITY=Developer ID Application: Your Name (YOUR_TEAMID)" \
  OTHER_CODE_SIGN_FLAGS="--timestamp" \
  ENABLE_HARDENED_RUNTIME=YES \
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO
```

Notes:

- `ENABLE_HARDENED_RUNTIME=YES` and `--timestamp` are required for notarization.
- `CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO` stops Xcode adding the debug-only `com.apple.security.get-task-allow` entitlement. Notarization rejects the app with "The executable requests the com.apple.security.get-task-allow entitlement" without it.

Verify the signature:

```bash
codesign --verify --deep --strict --verbose=2 build/Release/Caffeine.app
codesign -dvv build/Release/Caffeine.app 2>&1 | grep -E "Authority|TeamIdentifier|flags"
```

You should see your Developer ID authority, your team ID, and `flags=0x10000(runtime)`.

## 4. Notarize and staple

```bash
ditto -c -k --keepParent build/Release/Caffeine.app Caffeine.zip
xcrun notarytool submit Caffeine.zip --keychain-profile caffeine-notary --wait
```

If the status is `Accepted`, staple the ticket to the app and verify it:

```bash
xcrun stapler staple build/Release/Caffeine.app
xcrun stapler validate build/Release/Caffeine.app
spctl -a -vv -t exec build/Release/Caffeine.app    # source=Notarized Developer ID
```

If the status is `Invalid`, read the log using the submission id printed by the submit command:

```bash
xcrun notarytool log SUBMISSION_ID --keychain-profile caffeine-notary
```

## 5. Package for distribution

Zip the stapled app. Do this after stapling, so the zip contains the ticket:

```bash
ditto -c -k --keepParent build/Release/Caffeine.app Caffeine-2.0.0.zip
```

Test the result by downloading the zip onto another Mac (so it is quarantined) and opening the app. It should launch with no Gatekeeper warning.

## Version number

The version shown in the About dialog comes from `CFBundleShortVersionString` and `CFBundleVersion` in `Info.plist`. Update both for a new release, and update the zip name to match.

## Troubleshooting

- **`unable to find sdk 'macosx10.6'`**: the project's SDK setting is `macosx` (latest). Make sure `SDKROOT` hasn't been reset to an old value.
- **No identity found / "No certificate for team"**: check `security find-identity -v -p codesigning` and make sure the name passed to `CODE_SIGN_IDENTITY` matches exactly.
- **`No Keychain password item found for profile`**: run the `store-credentials` command in step 2 again.
- **App won't open on another Mac**: it was probably signed ad-hoc or not notarized. Re-check steps 3 and 4. Quarantine can also be cleared for testing with `xattr -dr com.apple.quarantine Caffeine.app`.
