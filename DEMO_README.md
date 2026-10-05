# Signal Keeper demo

This build targets Android (not native HarmonyOS). The desktop editor remains useful for previewing the same portrait game.

## Play

- Ten distinct rounds, ending in Mission Complete after round 10.
- Tap/click a pipe to rotate it clockwise. Each rotation costs one move.
- Round move limits: 6, 8, 12, 12, 13, 16, 19, 15, 24, 26.
- At zero moves the board locks; a win on the final move still counts.
- Restart Round is free and preserves completed rounds' rewards.
- Undo with Ad reverses the most recent rotation and refunds one move. It is available before or after reaching the limit.
- The debug/demo build uses a clearly labeled, five-second local ad simulation. Claim after the countdown to undo. Cancellation, failure and duplicate callbacks never grant extra rewards.
- Three stars for meeting the round's target, two for one extra move, one for two extra moves. Up to 30 stars / 10,000 points across the campaign. Rewards are per playthrough, not saved unlocks.

## Android identity and certificate

- Demo package: `com.hovahdigitalsolutions.signalkeeper`
- Display name: Signal Keeper Demo
- Version: 0.2.0-demo
- Debug signing alias: androiddebugkey
- SHA-256 fingerprint:

```text
EB:71:7B:02:B8:25:CC:CD:A9:D2:37:36:76:07:F6:16:73:05:8C:8B:F4:59:0F:ED:01:19:70:63:E9:15:AA:DB
```

This is the Android package name selected by the user for Huawei registration. A release signing certificate will have a different fingerprint. Register the certificate that actually signs the APK under test; do not use the APK file's SHA-256 hash as a certificate fingerprint.

## Huawei Petal Ads integration status

No live ads or real Petal SDK are included in this demo. No ad-unit ID is configured and the demo requires no ad network.

The game exposes `rewarded_ad_requested(request_id)`, `rewarded_ad_earned(request_id)` and `rewarded_ad_failed(request_id)` as integration points. A future Android Godot plugin should connect Huawei's earned-reward callback to `rewarded_ad_earned`, and cancellation/failure to the corresponding no-reward path. Each request is single-use and invalidated on cancellation or round restart. Do not grant rewards merely because an ad closed.

Real integration still needs a Petal rewarded-ad unit for the Android app, a native Android SDK plugin, and device testing. The current Android Demo preset explicitly enables `demo_ads`; remove that feature for a production build and connect the actual provider. Without a provider, non-demo builds show an unavailable message and keep free restart available.

References: [Huawei rewarded-ad sample](https://github.com/HMS-Core/hms-ads-demo-java/blob/master/app/src/main/java/com/huawei/hms/ads/sdk/RewardActivity.java), [Godot Android plugins](https://docs.godotengine.org/en/stable/tutorials/platform/android/android_plugin.html).

## Verification

`.verification/mobile_completion_qa.gd` checks all ten solutions, unique layouts, budget exhaustion, last-move wins, rewards, touch controls, demo completion/cancellation, duplicate and stale callbacks, restart and replay.

The development MCP runtime is disabled in exported games.
