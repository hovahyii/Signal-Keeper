# Huawei Petal rewarded ads

## Registration

- Android package: `com.hovahdigitalsolutions.signalkeeper`
- Huawei app ID: `119227547`
- Live rewarded unit: `g0cz46kwsu`
- SDK test rewarded unit: `testx9dtjwj8hp`
- SDK dependency: `com.huawei.hms:ads-lite:13.4.90.300`

The native Gradle build validates the supplied root `agconnect-services.json` against the app ID and package. The app ID is installed in the Android manifest as `com.huawei.hms.client.appid`. The JSON is excluded from the Godot game resources. This Ads-only integration does not add unrelated HMS services.

## Builds

- **Android Demo:** offline, simulated five-second ad. No native SDK build.
- **Android Petal Test:** actual Huawei SDK with the official test unit. Use this for ad playback testing before app release.
- **Android Petal Live:** actual Huawei SDK with `g0cz46kwsu`. No simulated reward fallback, even in debug builds.

The Test and Live builds use the same package; installing one updates/replaces the other. Debug-signed APKs are for device testing, not a production signing configuration.

## Reward behavior

Only the SDK's `onRewarded` callback marks a reward earned. Once the ad closes, the game receives a single reward notification and reverses one rotation/refunds one move. Closing early, declining the disclosure, cancelling loading, no-fill errors, timeout, and stale/duplicate callbacks do not award a move. Restart is always free.

No ad is loaded at game launch. A player chooses Watch Ad, sees an optional-ad disclosure, and can decline. Requests use non-personalized ads and do not request location permission. SDK load/show calls and request state run on the Android UI thread. The SDK load has a 30-second timeout.

## Source layout

- `addons/petal_ads/petal_bridge.gd`: request IDs, SDK signals and game callbacks.
- `addons/petal_ads/android/src/.../PetalAds.java`: native SDK loading, disclosure, callback handling and cleanup.
- `addons/petal_ads/export_plugin.gd`: SDK dependency, Huawei repository and manifest metadata.
- `android/build`: installed Godot 4.7.2 Gradle template. Its `build.gradle` includes the external Java source directory and validates the Huawei JSON. Preserve those two customizations if reinstalling the template.

## Device verification and release

Use the SDK-test APK on a compatible Android device with HMS Core and network access. Test completion, early close, unavailable network, repeated taps, background/resume and multiple undos. A successful compile is not proof of ad delivery. Formal ad delivery also depends on Huawei's app status, fill, service region and monetization approval.

Before store submission, configure release signing and register that certificate's fingerprint, publish the app's own privacy policy covering the actual SDK/data use, and complete Huawei's acceptance requirements. The in-app disclosure is not a substitute for the full app privacy policy or any region-specific consent requirements. This task does not publish the app or claim Huawei policy approval.

Official references: [Huawei rewarded-ad sample](https://github.com/HMS-Core/hms-ads-demo-java/blob/master/app/src/main/java/com/huawei/hms/ads/sdk/RewardActivity.java), [testing and release](https://developer.huawei.com/consumer/en/doc/distribution/monetize/release-0000001050961874), [Godot Android plugins](https://docs.godotengine.org/en/stable/tutorials/platform/android/android_plugin.html).
