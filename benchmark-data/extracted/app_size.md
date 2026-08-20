# Application size

All artefacts below were built during this extraction (2026-08-20) with
**Xcode 26.6 (17F113)** on **macOS 26.6.1 (25G76)**, and AGP 8.13.2 / Kotlin
2.2.21 for Android. These are **not** the toolchain versions that produced the
benchmark data — those are UNKNOWN for iOS (see `environment.md`).

Sizes are `du -sk` (on-disk, 1 KiB blocks) for `.app` bundles and `stat` byte
counts for single files. 1 MB = 1,048,576 bytes.

## Summary table

| Target | Artifact type | Size (MB) | Raw size | Build config | Caveats |
|---|---|---|---|---|---|
| KMP Android (`composeApp`) | APK, unsigned | **55.78** | 58,486,922 B | `release`, `isMinifyEnabled = false` | R8/shrinking **off**; universal APK, 4 ABIs. Not a shippable size. |
| KMP iOS (`iosApp`) | `.app`, device arm64, unstripped | **52.30** | 53,556 KB | `Release`, unsigned (`CODE_SIGNING_ALLOWED=NO`) | Signing disabled to get past provisioning; does not affect binary size materially. |
| KMP iOS (`iosApp`) | `.app`, device arm64, **stripped** | **39.78** | 40,736 KB | `Release` + `strip -rSTx` | Stripped locally as an archive proxy; not a real archive. |
| KMP iOS (`iosApp`) | compressed `.ipa` **proxy** | **13.17** | 13,815,577 B | stripped, zipped as `Payload/` | **Not a signed IPA** — a zip proxy for compressed size. |
| Native iOS (`IosNativeBuild`) | `.app`, device arm64, unstripped | **1.49** | 1,528 KB | `Release`, signed | Debug symbols still in the binary. |
| Native iOS (`IosNativeBuild`) | `.app`, from archive (stripped) | **0.45** | 464 KB | `Release`, archived | Symbols moved to dSYM. |
| Native iOS (`IosNativeBuild`) | **IPA** (real) | **0.159** | 166,655 B | `Release`, `method: debugging`, `stripSwiftSymbols` | Genuine signed export. |
| Native iOS (`IosNativeBuild`) | `.app`, simulator | 2.90 | 2,972 KB | `Release`, simulator | **Simulator build** — reference only, not a device size. |

### The like-for-like iOS comparison

Comparing artefacts produced the same way:

| Stage | KMP iOS (Compose Multiplatform) | Native iOS (SwiftUI) | Ratio |
|---|---|---|---|
| Device `.app`, unstripped | 52.30 MB | 1.49 MB | **35×** |
| Device `.app`, stripped | 39.78 MB | 0.45 MB | **88×** |
| Compressed (proxy vs real IPA) | 13.17 MB | 0.159 MB | **83×** |
| Main binary, unstripped | 54,736,760 B | 1,539,840 B | 36× |
| Main binary, stripped | 41,610,120 B | 447,856 B | 93× |

**This is a genuine framework finding, unlike the Android APK number below.**
Both sides are single-architecture (arm64) device Release builds of the same
app, processed identically at each stage. The gap is real: Compose Multiplatform
statically links the Skia renderer, the Compose runtime and the Kotlin/Native
runtime into the app binary, whereas SwiftUI draws on frameworks already present
in iOS and ships almost nothing.

Caveats to state alongside it:

- The KMP stripped and compressed figures are **local proxies** (`strip -rSTx`,
  then `zip`), not the output of `xcodebuild archive`/`-exportArchive`, because
  KMP iOS archiving is blocked by provisioning (below). The native column at
  those two rows *is* a real archive and a real signed IPA. Expect the true KMP
  archive/IPA to land near the proxy but not exactly on it.
- Neither iOS app uses app thinning or on-demand resources, so no per-device
  slicing benefit is reflected on either side.
- The KMP `.app` contains one statically linked Mach-O
  (`Thesisproject`, 52.20 MB) and no `Frameworks/` directory — the
  `ComposeApp.framework` is linked in rather than embedded.

## Android detail

```sh
ANDROID_HOME=~/Library/Android/sdk ./gradlew :composeApp:assembleRelease
```

Output: `kmp-app/composeApp/build/outputs/apk/release/composeApp-release-unsigned.apk`
— 58,486,922 bytes (**55.78 MB**).

### R8 / minification: OFF

`kmp-app/composeApp/build.gradle.kts:106-116`:

```kotlin
buildTypes {
    getByName("release") {
        isMinifyEnabled = false
    }
    create("benchmark") {
        initWith(getByName("release"))
        signingConfig = signingConfigs.getByName("debug")
        matchingFallbacks += listOf("release")
        isDebuggable = false
    }
}
```

No `isMinifyEnabled = true`, no `isShrinkResources`, no ProGuard/R8 rules files.

### Why 55.78 MB is not a meaningful cross-platform size

| Entry | Uncompressed |
|---|---|
| `classes.dex` | 29,993,484 B |
| `classes2.dex` | 12,441,172 B |
| `classes3.dex` | 9,965,552 B |
| `lib/arm64-v8a/libsqliteJni.so` | 1,310,776 B |
| `lib/armeabi-v7a/libsqliteJni.so` | 1,253,332 B |
| `lib/x86_64/libsqliteJni.so` | 1,220,840 B |
| `lib/x86/libsqliteJni.so` | 1,159,896 B |
| `resources.arsc` | 669,816 B |
| `assets/PublicSuffixDatabase.list` | 132,737 B |

Two effects dominate, and **neither is a property of Kotlin Multiplatform**:

1. **~52.4 MB of unminified dex** across three files. With R8 off, the entire
   Compose runtime, Ktor, Room, Coil, Koin and the Kotlin stdlib are retained
   whole — no tree-shaking, no obfuscation, no dead-code removal.
2. **Four ABI slices** of `libsqliteJni.so` (~4.9 MB uncompressed) where only
   `arm64-v8a` is needed for the Pixel 8.

**Do not report "55.78 MB Android vs 0.159 MB native iOS" as a framework
finding.** That pairing compares an unminified universal APK against a stripped,
signed, single-architecture IPA. To make it honest, rebuild Android with
`isMinifyEnabled = true` + `isShrinkResources = true` and an ABI split (or a
`bundletool`-extracted arm64 APK).

The **iOS** comparison in the previous section does not suffer from this problem,
which is why it is the one to quote.

### Baseline profile

The release variant embeds a baseline profile via
`baselineProfile(project(":baselineprofile"))`
(`composeApp/build.gradle.kts:125`). There is **no separate
baseline-profile-free release variant**, so no size delta between profile and
non-profile builds can be reported; its contribution to the 55.78 MB is not
separately attributable from this artefact.

Note also that the **benchmarked** Android artefact was the `benchmark` build
type (release-derived, debug-signed, non-debuggable), not the `release` APK
measured here.

## iOS commands used

### Native iOS — device, archive, IPA

```sh
xcodebuild -scheme IosNativeBuild -project IosNativeBuild.xcodeproj \
  -configuration Release -destination 'generic/platform=iOS' \
  -derivedDataPath ./dd build                                        # BUILD SUCCEEDED, signed

xcodebuild -scheme IosNativeBuild -project IosNativeBuild.xcodeproj \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath native.xcarchive archive                              # ARCHIVE SUCCEEDED

xcodebuild -exportArchive -archivePath native.xcarchive \
  -exportPath native_export -exportOptionsPlist ExportOptions.plist \
  -allowProvisioningUpdates                                          # EXPORT SUCCEEDED
```

Export options: `method: debugging`, `signingStyle: automatic`,
`stripSwiftSymbols: true`, `compileBitcode: false`. Whole `.xcarchive`
(app + dSYMs): 2,980 KB; dSYM DWARF alone 2,563,812 B.

### KMP iOS — device build

Succeeded only on the third attempt:

| Attempt | Destination | Result |
|---|---|---|
| 1 | `generic/platform=iOS` (Release) | **Failed — code signing.** `No profiles for 'com.example.thesisproject.Thesisproject' were found… Automatic signing is disabled and unable to generate a profile.` |
| 2 | `generic/platform=iOS Simulator` (Release) | **Failed — `java.lang.OutOfMemoryError: Java heap space`** in `:composeApp:linkReleaseFrameworkIosX64`, inside `org.jetbrains.kotlin.backend.konan.optimizations.DevirtualizationAnalysis`. Repo default is `kotlin.daemon.jvmargs=-Xmx3072M`; raising *that* to 8 GB did not help. |
| 3 | `generic/platform=iOS` (Release), signing off, `kotlin.native.jvmArgs=-Xmx10g` | **BUILD SUCCEEDED** |

```sh
# after temporarily setting kotlin.native.jvmArgs=-Xmx10g
ANDROID_HOME=~/Library/Android/sdk \
xcodebuild -scheme iosApp -project iosApp.xcodeproj \
  -configuration Release -destination 'generic/platform=iOS' \
  -derivedDataPath ./dd_kmp_dev \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" build
```

Two findings worth carrying forward:

- The heap knob that matters is **`kotlin.native.jvmArgs`**, not
  `kotlin.daemon.jvmargs` — the OOM is in the Kotlin/Native compiler, which the
  daemon setting does not govern.
- Release-mode Kotlin/Native framework linking for this project is expensive
  (whole-program `DevirtualizationAnalysis`); budget for it rather than running
  it per size check.

`kmp-app/gradle.properties` was restored to its original contents; the committed
tree contains **no** build-config change from this extraction.

### KMP iOS stripped and compressed proxies

```sh
cp -R Thesisproject.app Thesisproject_stripped.app
strip -rSTx Thesisproject_stripped.app/Thesisproject     # 54,736,760 -> 41,610,120 B
mkdir -p Payload && mv Thesisproject_stripped.app Payload/Thesisproject.app
zip -qry kmp_proxy.ipa Payload                           # 13,815,577 B
```

Labelled a **proxy** throughout: it is not a signed IPA and did not pass through
`xcodebuild archive`.

## Remaining gap

A **real** KMP iOS archive and signed IPA were not produced, because archiving
requires provisioning for `com.example.thesisproject.Thesisproject`. With a
development team selected:

```sh
xcodebuild -scheme iosApp -project kmp-app/iosApp/iosApp.xcodeproj \
  -configuration Release -destination 'generic/platform=iOS' \
  -allowProvisioningUpdates -archivePath kmp.xcarchive archive
xcodebuild -exportArchive -archivePath kmp.xcarchive -exportPath kmp_export \
  -exportOptionsPlist ExportOptions.plist -allowProvisioningUpdates
```

(after setting `kotlin.native.jvmArgs=-Xmx10g` or higher). That would replace the
two proxy rows with measured values. The unstripped `.app` comparison — 52.30 MB
vs 1.49 MB — is already a real, like-for-like measurement and needs no
follow-up.
