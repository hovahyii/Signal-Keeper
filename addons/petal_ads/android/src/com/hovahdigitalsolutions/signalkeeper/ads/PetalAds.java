package com.hovahdigitalsolutions.signalkeeper.ads;

import android.app.Activity;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
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
    private static final String TAG = "SignalKeeperAds";
    private static final String TEST_UNIT = "testx9dtjwj8hp";
    private final Handler ui = new Handler(Looper.getMainLooper());
    private Session active;

    private static final class Session {
        final int id;
        final String originalUnit;
        boolean earned;
        boolean triedFallback;
        RewardAd ad;
        Runnable timeout;
        Session(int id, String originalUnit) {
            this.id = id;
            this.originalUnit = originalUnit;
        }
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
            if (activity == null || activity.isFinishing()) {
                emitSignal("ad_failed", requestId, "Activity unavailable");
                return;
            }
            if (active != null) {
                // If previous session is lingering, clean it up
                finish(active, "ad_cancelled", "");
            }
            Session session = new Session(requestId, unitId);
            active = session;
            load(session, unitId);
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
            Log.i(TAG, "Initializing HwAds and loading rewarded ad: " + unitId);
            HwAds.init(activity);
            session.ad = new RewardAd(activity, unitId);
            session.timeout = () -> {
                Log.w(TAG, "Ad load timed out for: " + unitId);
                if (!session.triedFallback && !TEST_UNIT.equals(unitId)) {
                    session.triedFallback = true;
                    Log.i(TAG, "Retrying with Petal test unit: " + TEST_UNIT);
                    load(session, TEST_UNIT);
                } else {
                    finish(session, "ad_failed", "Ad load timed out");
                }
            };
            ui.postDelayed(session.timeout, 12000);
            session.ad.loadAd(new AdParam.Builder().setNonPersonalizedAd(1).build(), new RewardAdLoadListener() {
                @Override public void onRewardAdFailedToLoad(int code) {
                    ui.post(() -> {
                        if (active != session) return;
                        Log.w(TAG, "Failed to load " + unitId + " code: " + code);
                        if (!session.triedFallback && !TEST_UNIT.equals(unitId)) {
                            session.triedFallback = true;
                            ui.removeCallbacks(session.timeout);
                            Log.i(TAG, "Falling back to Petal test unit: " + TEST_UNIT);
                            load(session, TEST_UNIT);
                        } else {
                            finish(session, "ad_failed", "Load code " + code);
                        }
                    });
                }
                @Override public void onRewardedLoaded() {
                    ui.post(() -> {
                        if (active != session) return;
                        Log.i(TAG, "Rewarded ad loaded successfully: " + unitId);
                        show(session);
                    });
                }
            });
        } catch (Exception error) {
            Log.e(TAG, "Exception loading ad: " + error.getMessage(), error);
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
        if (session.timeout != null) {
            ui.removeCallbacks(session.timeout);
        }
        try {
            session.ad.show(activity, new RewardAdStatusListener() {
                @Override public void onRewardAdOpened() {
                    ui.post(() -> {
                        if (active == session) {
                            Log.i(TAG, "Ad opened on screen");
                            emitSignal("ad_opened", session.id);
                        }
                    });
                }
                @Override public void onRewarded(Reward reward) {
                    ui.post(() -> {
                        if (active == session) {
                            Log.i(TAG, "Reward earned by player");
                            session.earned = true;
                        }
                    });
                }
                @Override public void onRewardAdClosed() {
                    ui.post(() -> {
                        Log.i(TAG, "Ad closed. Earned: " + session.earned);
                        finish(session, session.earned ? "reward_earned" : "ad_cancelled", "");
                    });
                }
                @Override public void onRewardAdFailedToShow(int code) {
                    ui.post(() -> {
                        Log.w(TAG, "Ad failed to show: " + code);
                        finish(session, "ad_failed", "Show code " + code);
                    });
                }
            });
        } catch (Exception error) {
            Log.e(TAG, "Exception showing ad: " + error.getMessage(), error);
            finish(session, "ad_failed", error.getClass().getSimpleName());
        }
    }

    private void finish(Session session, String signal, String error) {
        if (active != session) return;
        active = null;
        if (session.timeout != null) ui.removeCallbacks(session.timeout);
        if (session.ad != null) {
            try { session.ad.destroy(); } catch (Exception ignored) {}
        }
        if ("ad_failed".equals(signal)) {
            emitSignal(signal, session.id, error);
        } else {
            emitSignal(signal, session.id);
        }
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
