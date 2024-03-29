package io.flutter.plugins.vponmobileads;

import android.util.Log;

class VponFlutterInterstitialAd {

    private static final String TAG = "VFlutterInterstitialAd";

    private final int adSeqId;
    private final String licenseKey;
    private final VponFlutterAdRequest flutterAdRequest;

    VponFlutterInterstitialAd(int adSeqId, VponAdInstanceManager adInstanceManager
            , String licenseKey, VponFlutterAdRequest adRequest, VponFlutterAdLoader adLoader) {
        this.adSeqId = adSeqId;
        this.licenseKey = licenseKey;
        this.flutterAdRequest = adRequest;
    }

    void load(){
        Log.e(TAG, "load invoked!!");
    }

}
