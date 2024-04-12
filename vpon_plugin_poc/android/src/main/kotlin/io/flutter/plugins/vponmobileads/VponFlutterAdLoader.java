package io.flutter.plugins.vponmobileads;

import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;

import com.vpon.ads.VponAdListener;
import com.vpon.ads.VponAdLoader;
import com.vpon.ads.VponAdRequest;
import com.vpon.ads.VponInterstitialAd;
import com.vpon.ads.VponInterstitialAdLoadCallback;
import com.vpon.ads.VponNativeAd;

class VponFlutterAdLoader {

    private static final String TAG = "VponFlutterAdLoader";

    private final Context context;

    VponFlutterAdLoader(Context context) {
        this.context = context;
    }

    void loadInterstitial(@NonNull final String licenseKey
            , @NonNull final VponAdRequest vponAdRequest
            , final VponInterstitialAdLoadCallback vponInterstitialAdLoadCallback) {
        Log.e(TAG, "loadInterstitial invoked!!");
        VponInterstitialAd.load(context, licenseKey, vponAdRequest, vponInterstitialAdLoadCallback);
    }

    public void loadNativeAd(
            @NonNull final String licenseKey,
            @NonNull final VponNativeAd.OnNativeAdLoadedListener onNativeAdLoadedListener,
            @NonNull final VponAdListener adListener,
            @NonNull final VponAdRequest adRequest) {
        Log.e(TAG, "loadNativeAd invoked!!");
        new VponAdLoader
                .Builder(context, licenseKey)
                .withAdListener(adListener)
                .forNativeAd(onNativeAdLoadedListener)
                .build()
                .loadAd(adRequest);
    }
}
