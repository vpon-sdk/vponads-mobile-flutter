package io.flutter.plugins.vponmobileads;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.vpon.ads.VponAdRequest;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

class VponAdInstanceManager {

    private static final String TAG = "VponAdInstanceManager";

    @NonNull
    private final Map<Integer, VponFlutterAd> ads;
    @NonNull
    private final MethodChannel channelToDart;

    VponAdInstanceManager(@NonNull MethodChannel channel) {
        this.channelToDart = channel;
        this.ads = new HashMap<>();
    }

    void onAdLoaded(VponFlutterAd vponFlutterAd) {
        Log.e(TAG, "VponAdInstanceManager invoke onAdEvent onAdLoaded");

        trackAd(vponFlutterAd.adId, vponFlutterAd);

        Map<Object, Object> arguments = new HashMap<>();
        arguments.put(Constants.CHANNEL_ARGUMENT_ADID, vponFlutterAd.adId);
        arguments.put(Constants.CHANNEL_ARGUMENT_EVENT_NAME, "onAdLoaded");
        invokeOnAdEvent(arguments);
    }

    private void trackAd(int adId, VponFlutterAd vponFlutterAd) {
        if (ads.get(adId) != null) {
            throw new IllegalArgumentException(
                    String.format("Ad for following adId already exists: %d", adId));
        }
        ads.put(adId, vponFlutterAd);
    }

    void onAdFailedToLoad(VponFlutterAd vponFlutterAd
            , VponAdRequest.VponErrorCode vponErrorCode) {
        Log.e(TAG, "VponAdInstanceManager invoke onAdEvent " +
                "onAdFailedToLoad(" + vponErrorCode.getErrorCode() + ")");
        Map<Object, Object> arguments = new HashMap<>();
        arguments.put(Constants.CHANNEL_ARGUMENT_ADID, vponFlutterAd.adId);
        Map<Object, Object> errors = new HashMap<>();
        errors.put(Constants.CHANNEL_ARGUMENT_ERROR_DESCRIPTION
                , vponErrorCode.getErrorDescription());
        errors.put(Constants.CHANNEL_ARGUMENT_ERROR_CODE, vponErrorCode.getErrorCode());
        arguments.put(Constants.CHANNEL_ARGUMENT_LOAD_AD_ERROR, errors);
        invokeOnAdEvent(arguments);
    }


    private void invokeOnAdEvent(final Map<Object, Object> arguments) {
        new Handler(Looper.getMainLooper())
                .post(() -> channelToDart
                        .invokeMethod(Constants.CHANNEL_ARGUMENT_ON_AD_EVENT, arguments));
    }

    void disposeAd(int adId) {
        if (!ads.containsKey(adId)) {
            return;
        }
        VponFlutterAd ad = ads.get(adId);
        if (ad != null) {
            ad.dispose();
        }
        ads.remove(adId);
    }

    void disposeAllAds() {
        for (Map.Entry<Integer, VponFlutterAd> entry : ads.entrySet()) {
            if (entry.getValue() != null) {
                entry.getValue().dispose();
            }
        }
        ads.clear();
    }

    @Nullable
    VponFlutterAd adForId(int id) {
        return ads.get(id);
    }
}
