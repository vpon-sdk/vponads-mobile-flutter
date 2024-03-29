package io.flutter.plugins.vponmobileads;

import android.content.Context;
import android.util.Log;

import com.vpon.ads.VponAdRequest;
import com.vpon.ads.VponInterstitialAd;
import com.vpon.ads.VponInterstitialAdLoadCallback;

class VponFlutterAdLoader {

    private static final String TAG = "VponFlutterAdLoader";

    private final Context context;

    VponFlutterAdLoader(Context context) {
        this.context = context;
    }

    void loadInterstitial(final String licenseKey, final VponAdRequest vponAdRequest
            , final VponInterstitialAdLoadCallback vponInterstitialAdLoadCallback) {
        Log.e(TAG, "loadInterstitial invoked!!");
        VponInterstitialAd.load(context, licenseKey, vponAdRequest, vponInterstitialAdLoadCallback);
    }
}
