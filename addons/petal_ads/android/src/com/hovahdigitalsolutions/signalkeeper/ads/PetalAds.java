package com.hovahdigitalsolutions.signalkeeper.ads;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Intent;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import com.huawei.hms.ads.AdParam;
import com.huawei.hms.ads.HwAds;
import com.huawei.hms.ads.reward.Reward;
import com.huawei.hms.ads.reward.RewardAd;
import com.huawei.hms.ads.reward.RewardAdLoadListener;
import com.huawei.hms.ads.reward.RewardAdStatusListener;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

/** All SDK and request-state operations run on the Android UI thread. */
public final class PetalAds extends GodotPlugin {
    private static final String SDK_PRIVACY = "https://developer.huawei.com/consumer/en/doc/HMSCore-Guides/whale-hong-kinetic-energy-sdk-privacy-statement-0000001658283582";
    private final Handler ui = new Handler(Looper.getMainLooper());
    private Session active;

    private static final class Session {
        final int id;
        boolean earned;
        RewardAd ad;
        AlertDialog disclosure;
        Runnable timeout;
        Session(int id) { this.id = id; }
    }

    public PetalAds(Godot godot) { super(godot); }
    @Override public String getPluginName() { return "PetalAds"; }
    @Override public Set<SignalInfo> getPluginSignals() {
        return new HashSet<>(Arrays.asList(
            new SignalInfo("reward_earned", Integer.class),
            new SignalInfo("ad_cancelled", Integer.class),
            new SignalInfo("ad_failed", Integer.class, String.class),
            new SignalInfo("ad_opened", Integer.class)
        ));
    }

    @UsedByGodot public void show_rewarded(int requestId, String unitId) {
        ui.post(() -> {
            Activity activity = getActivity();
            if (activity == null || activity.isFinishing() || active != null) {
                emitSignal("ad_failed", requestId, "Activity unavailable or another ad is active");
                return;
            }
            Session session = new Session(requestId);
            active = session;
            // No SDK initialization or ad request until the player chooses Continue.
            session.disclosure = new AlertDialog.Builder(activity)
                .setTitle("Signal Keeper · optional rewarded ad")
                .setMessage("Watch a Huawei Petal ad to undo one rotation and restore one move. "
                    + "Huawei may process device identifiers, device/app/network information and ad interactions "
                    + "to deliver ads and prevent fraud, and may start HMS Core or AppGallery. "
                    + "This game requests non-personalized ads and does not request location permission. "
                    + "You can cancel and restart the round for free instead.")
                .setPositiveButton("Continue", (dialog, which) -> load(session, unitId))
                .setNegativeButton("Cancel", (dialog, which) -> finish(session, "ad_cancelled", ""))
                .setNeutralButton("Huawei SDK privacy", (dialog, which) -> {
                    finish(session, "ad_cancelled", "");
                    try { activity.startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(SDK_PRIVACY))); }
                    catch (RuntimeException ignored) { /* The game remains available. */ }
                })
                .setOnCancelListener(dialog -> finish(session, "ad_cancelled", ""))
                .create();
            session.disclosure.show();
        });
    }

    private void load(Session session, String unitId) {
        if (active != session) return;
        Activity activity = getActivity();
        if (activity == null || activity.isFinishing()) {
            finish(session, "ad_failed", "Activity unavailable");
            return;
        }
        try {
            HwAds.init(activity);
            session.ad = new RewardAd(activity, unitId);
            session.timeout = () -> finish(session, "ad_failed", "Ad load timed out");
            ui.postDelayed(session.timeout, 30000);
            session.ad.loadAd(new AdParam.Builder().setNonPersonalizedAd(1).build(), new RewardAdLoadListener() {
                @Override public void onRewardAdFailedToLoad(int code) {
                    ui.post(() -> finish(session, "ad_failed", "Load code " + code));
                }
                @Override public void onRewardedLoaded() {
                    ui.post(() -> show(session));
                }
            });
        } catch (RuntimeException error) {
            finish(session, "ad_failed", error.getClass().getSimpleName());
        }
    }

    private void show(Session session) {
        if (active != session) return;
        Activity activity = getActivity();
        if (activity == null || activity.isFinishing()) {
            finish(session, "ad_failed", "Activity unavailable");
            return;
        }
        ui.removeCallbacks(session.timeout);
        try {
            session.ad.show(activity, new RewardAdStatusListener() {
                @Override public void onRewardAdOpened() {
                    ui.post(() -> { if (active == session) emitSignal("ad_opened", session.id); });
                }
                @Override public void onRewarded(Reward reward) {
                    ui.post(() -> { if (active == session) session.earned = true; });
                }
                @Override public void onRewardAdClosed() {
                    ui.post(() -> finish(session, session.earned ? "reward_earned" : "ad_cancelled", ""));
                }
                @Override public void onRewardAdFailedToShow(int code) {
                    ui.post(() -> finish(session, "ad_failed", "Show code " + code));
                }
            });
        } catch (RuntimeException error) {
            finish(session, "ad_failed", error.getClass().getSimpleName());
        }
    }

    private void finish(Session session, String signal, String error) {
        if (active != session) return;
        active = null; // Clear first: duplicate/reentrant callbacks cannot award twice.
        if (session.timeout != null) ui.removeCallbacks(session.timeout);
        if (session.disclosure != null) session.disclosure.dismiss();
        if (session.ad != null) session.ad.destroy();
        if ("ad_failed".equals(signal)) emitSignal(signal, session.id, error);
        else emitSignal(signal, session.id);
    }

    @UsedByGodot public void cancel_rewarded(int requestId) {
        ui.post(() -> {
            if (active != null && active.id == requestId) finish(active, "ad_cancelled", "");
        });
    }

    @Override public void onMainDestroy() {
        ui.post(() -> { if (active != null) finish(active, "ad_cancelled", ""); });
        super.onMainDestroy();
    }
}
