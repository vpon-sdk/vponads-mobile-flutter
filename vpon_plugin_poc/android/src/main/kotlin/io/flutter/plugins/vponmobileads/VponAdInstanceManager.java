package io.flutter.plugins.vponmobileads;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;

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
        Map<Object, Object> arguments = new HashMap<>();
        arguments.put(Utils.adId, vponFlutterAd.adId);
        arguments.put(Utils.eventName, "onAdLoaded");
        invokeOnAdEvent(arguments);
    }

    void onAdFailedToLoad(VponFlutterAd vponFlutterAd
            , VponAdRequest.VponErrorCode vponErrorCode){
        Log.e(TAG, "VponAdInstanceManager invoke onAdEvent onAdLoaded");
        Map<Object, Object> arguments = new HashMap<>();
        arguments.put(Utils.adId, vponFlutterAd.adId);
        Map<Object, Object> errors = new HashMap<>();
        errors.put(Utils.errorDescription, vponErrorCode.getErrorDescription());
        errors.put(Utils.errorCode, vponErrorCode.getErrorCode());
        arguments.put(Utils.loadAdError, errors);
        invokeOnAdEvent(arguments);
    }


    private void invokeOnAdEvent(final Map<Object, Object> arguments) {
        new Handler(Looper.getMainLooper())
                .post(() -> channelToDart.invokeMethod(Utils.onAdEvent, arguments));
    }


}
