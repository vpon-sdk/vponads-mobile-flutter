package io.flutter.plugins.vponmobileads;

import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.vpon.ads.VponAdRequest;
import com.vpon.ads.VponInterstitialAd;
import com.vpon.ads.VponInterstitialAdLoadCallback;

import java.lang.ref.WeakReference;

class VponFlutterInterstitialAd extends VponFlutterAd.VponFlutterOverlayAd {

    private static final String TAG = "VFlutterInterstitialAd";

    private final String licenseKey;
    private final VponFlutterAdRequest flutterAdRequest;
    private final VponAdInstanceManager adInstanceManager;
    private final VponFlutterAdLoader adLoader;

    @Nullable
    private VponInterstitialAd vponInterstitialAd;

    VponFlutterInterstitialAd(int adSeqId, VponAdInstanceManager adInstanceManager
            , String licenseKey, VponFlutterAdRequest adRequest, VponFlutterAdLoader adLoader) {
        super(adSeqId);
        this.licenseKey = licenseKey;
        this.flutterAdRequest = adRequest;

        this.adLoader = adLoader;
        this.adInstanceManager = adInstanceManager;
    }

    @Override
    void load() {
        Log.e(TAG, "load invoked!!");
        if (adInstanceManager != null && licenseKey != null && flutterAdRequest != null) {
            adLoader.loadInterstitial(
                    licenseKey, flutterAdRequest.asVponAdRequest()
                    , new DelegatingInterstitialAdLoadCallback(this));
        }
    }

    @Override
    void dispose() {
        vponInterstitialAd = null;
    }

    @Override
    void show() {
        //TODO
    }

    private void onAdLoaded(VponInterstitialAd vponInterstitialAd) {
        Log.e(TAG, "onAdLoaded invoked!!");
        this.vponInterstitialAd = vponInterstitialAd;
        adInstanceManager.onAdLoaded(this);
    }

    void onAdFailedToLoad(VponAdRequest.VponErrorCode vponErrorCode) {
        Log.e(TAG, "onAdFailedToLoad("+vponErrorCode.getErrorCode()
                +"/"+vponErrorCode.getErrorDescription()+") invoked!!");
        adInstanceManager.onAdFailedToLoad(this,vponErrorCode);
    }

    private static final class DelegatingInterstitialAdLoadCallback
            extends VponInterstitialAdLoadCallback {

        private final WeakReference<VponFlutterInterstitialAd> delegate;

        DelegatingInterstitialAdLoadCallback(VponFlutterInterstitialAd vponFlutterInterstitialAd) {
            delegate = new WeakReference<>(vponFlutterInterstitialAd);
        }


        @Override
        public void onAdFailedToLoad(@NonNull VponAdRequest.VponErrorCode vponErrorCode) {
            if (delegate.get() != null) {
                delegate.get().onAdFailedToLoad(vponErrorCode);
            }
        }

        @Override
        public void onAdLoaded(VponInterstitialAd vponInterstitialAd) {
            if (delegate.get() != null) {
                delegate.get().onAdLoaded(vponInterstitialAd);
            }
        }
    }

}
