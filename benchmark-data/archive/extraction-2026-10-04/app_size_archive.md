# Application size — signed archives and IPAs

Closes the "Remaining gap" in `archive/extraction-2026-08-20/app_size.md`: a real
`xcodebuild archive` and a real signed `.ipa` for the KMP iOS app, replacing the
`strip -rSTx` + `zip` proxies used there. Both apps were archived and exported
identically, same day, same toolchain.

Raw values: `app_size_measurements.csv`.

## Toolchain

```
Xcode 27.0 (27A266a)            # xcodebuild -version
macOS 27.0 (26A428)             # sw_vers
```

Newer than the 2026-08-20 extraction (Xcode 26.6 / macOS 26.6.1) — see the
toolchain caveat below.

No `.pbxproj`, bundle ID or `Info.plist` was edited; signing settings were passed
as `xcodebuild` overrides. Code signing was enabled throughout.

## Commands

Export options (`method: debugging`, `signingStyle: automatic`,
`stripSwiftSymbols: true`, `compileBitcode: false`, `destination: export`); the
thinned variant adds `thinning: iPhone17,3`.

`kmp-app/gradle.properties` was temporarily appended with
`kotlin.native.jvmArgs=-Xmx10g` — the knob identified on 2026-08-20; the Release
framework link OOMs at 3 GB and at 8 GB, and `kotlin.daemon.jvmargs` does not
govern it. Restored byte-for-byte afterwards.

```sh
# KMP iOS
ANDROID_HOME=~/Library/Android/sdk \
xcodebuild -scheme iosApp -project kmp-app/iosApp/iosApp.xcodeproj \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath build/kmp.xcarchive \
  DEVELOPMENT_TEAM=<team> CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates archive

# Native iOS
xcodebuild -scheme IosNativeBuild -project native-ios-app/IosNativeBuild.xcodeproj \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath build/native.xcarchive \
  DEVELOPMENT_TEAM=<team> CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates archive

# Each archive exported twice — plain, then with thinning
xcodebuild -exportArchive -archivePath build/<x>.xcarchive \
  -exportPath build/<x>_export -exportOptionsPlist build/ExportOptions.plist \
  -allowProvisioningUpdates
```

All six invocations reported `ARCHIVE SUCCEEDED` / `EXPORT SUCCEEDED`.

## Measurements

`du -sk` is on-disk in 1 KiB blocks; `stat -f%z` is exact bytes; the payload
figure is the `unzip -l` total of uncompressed entries. 1 MB = 1,048,576 B.

| Stage | KMP iOS | Native iOS | Ratio |
|---|---|---|---|
| Archived `.app` (`du -sk`) | 40,712 KB — 41,689,088 B — **39.758 MB** | 464 KB — 475,136 B — **0.453 MB** | **87.74×** |
| Main binary (`stat -f%z`) | 41,565,952 B — **39.640 MB** | 449,520 B — **0.429 MB** | **92.47×** |
| Signed IPA | 13,873,834 B — **13.231 MB** | 164,397 B — **0.157 MB** | **84.39×** |
| Signed IPA, thinned | 13,873,676 B — 13.231 MB | 164,672 B — 0.157 MB | 84.25× |
| IPA payload uncompressed | 41,664,618 B (16 files) — 39.734 MB | 465,288 B (8 files) — 0.444 MB | 89.55× |
| dSYM DWARF | 38,608,824 B — 36.820 MB | 2,635,908 B — 2.514 MB | 14.65× |

## Verification

- **Signed:** `codesign -dv --verbose=2` on both archived `.app`s returns a full
  chain to Apple Root CA, `Format=app bundle with Mach-O thin (arm64)`,
  `Sealed Resources version=2`. Both bundles carry `_CodeSignature/` and
  `embedded.mobileprovision`.
- **Architecture:** `lipo -info` →
  `Non-fat file: … is architecture: arm64` for both main binaries. Single-slice,
  like-for-like.
- **No `Frameworks/` in the KMP `.app`.** Contents are `_CodeSignature`,
  `AppIcon60x60@2x.png`, `AppIcon76x76@2x~ipad.png`, `Assets.car`,
  `compose-resources`, `embedded.mobileprovision`, `Info.plist`, `PkgInfo`,
  `Thesisproject`. `ComposeApp.framework` is statically linked into the single
  Mach-O, not embedded — the central claim of the size finding, now confirmed on
  a signed archive rather than a dev build.

## Thinning changes nothing material

`thinning = iPhone17,3` produced **one** variant in each case, whose descriptor
list covers ~90 device/OS combinations rather than iPhone17,3 alone — neither app
has device-dependent resources to slice.

| | Unthinned | Thinned | Delta |
|---|---|---|---|
| KMP IPA | 13,873,834 B | 13,873,676 B | **−158 B (−0.001 %)** |
| Native IPA | 164,397 B | 164,672 B | **+275 B (+0.167 %)** |

Thinning slices the asset catalog (KMP `Assets.car` 70,200 → 44,040 B) but injects
thinning metadata into `Info.plist` (+3,269 B KMP, +5,219 B native). The native app
has no asset catalog in its bundle, so it pays the metadata cost with no slicing
benefit and ends up *larger*. After compression the effects cancel.

Quote the unthinned figures; the thinned ones are recorded for completeness.

## Delta vs the 2026-08-20 proxies

Every proxy landed within 0.5 % of the real artefact.

| Artefact | Proxy | Real | Delta |
|---|---|---|---|
| KMP stripped → archived `.app` | 40,736 KB — 39.781 MB | 40,712 KB — 39.758 MB | −24,576 B (**−0.06 %**) |
| KMP zip → signed IPA | 13,815,577 B — 13.176 MB | 13,873,834 B — 13.231 MB | +58,257 B (**+0.42 %**) |
| KMP stripped → archived binary | 41,610,120 B — 39.683 MB | 41,565,952 B — 39.640 MB | −44,168 B (−0.11 %) |

`strip -rSTx` removed slightly *more* than the archive pipeline does, so the real
archived `.app` and binary are marginally larger than the proxies. The real IPA is
marginally larger than the zip because it carries `_CodeSignature/`,
`embedded.mobileprovision` and a signed, less compressible binary.

Headline ratios barely move: 88× → **87.74×** at the `.app` stage, 83× → **84.39×**
compressed. The framework finding is unchanged and now rests on real signed
artefacts on both sides.

## Toolchain caveat

These artefacts were built with Xcode 27.0, whereas the 52.30 MB / 1.49 MB
**unstripped `.app`** row in `RESULTS.md` came from Xcode 26.6 (and its KMP side
was built unsigned). That row is therefore not strictly same-toolchain with the
rows here. An archive does not emit an unstripped `.app`, so re-deriving it needs
a separate non-archive build; it was left as it stands. All stage-to-stage ratios
*within* this extraction are same-toolchain and internally consistent, and sub-1 %
toolchain drift would not move a 35× ratio.

## Artefacts

The archives and IPAs are build output and are not committed (~105 MB, and the
`.app` bundles embed provisioning profiles). Reproduce with the commands above.
Nothing was installed on a device.
