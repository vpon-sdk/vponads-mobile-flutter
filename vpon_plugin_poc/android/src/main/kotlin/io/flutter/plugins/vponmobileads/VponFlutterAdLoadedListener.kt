package io.flutter.plugins.vponmobileads;

import com.vpon.ads.VponAdListener;
import com.vpon.ads.VponNativeAd;

import java.lang.ref.WeakReference;

interface VponFlutterAdLoadedListener {
    void onAdLoaded();
}

class VponFlutterAdListener extends VponAdListener {

    protected final int adId;
    protected final VponAdInstanceManager adInstanceManager;

    VponFlutterAdListener(int adId, VponAdInstanceManager adInstanceManager) {
        this.adId = adId;
        this.adInstanceManager = adInstanceManager;
    }

}

class VponFlutterBannerAdListener extends VponFlutterAdListener {

    final WeakReference<VponFlutterAdLoadedListener> adLoadedListenerWeakReference;

    VponFlutterBannerAdListener(int adId, VponAdInstanceManager adInstanceManager
            , VponFlutterAdLoadedListener vponFlutterAdLoadedListener) {
        super(adId, adInstanceManager);
        adLoadedListenerWeakReference = new WeakReference<>(vponFlutterAdLoadedListener);
    }

    @Override
    public void onAdLoaded() {
        adLoadedListenerWeakReference.get().onAdLoaded();
    }
}

class VponFlutterNativeAdListener extends VponFlutterAdListener {

    VponFlutterNativeAdListener(int adId, VponAdInstanceManager adInstanceManager) {
        super(adId, adInstanceManager);
    }
}

class VponFlutterNativeAdLoadedListener extends VponNativeAd.OnNativeAdLoadedListener {

    private final WeakReference<VponFlutterNativeAd>nativeAdWeakReference;
    VponFlutterNativeAdLoadedListener(VponFlutterNativeAd flutterNativeAd) {
        nativeAdWeakReference = new WeakReference<>(flutterNativeAd);
    }

    @Override
    public void onNativeAdLoaded( VponNativeAd nativeAd) {
        if (nativeAdWeakReference.get() != null) {
            nativeAdWeakReference.get().onNativeAdLoaded(nativeAd);
        }
    }

}

