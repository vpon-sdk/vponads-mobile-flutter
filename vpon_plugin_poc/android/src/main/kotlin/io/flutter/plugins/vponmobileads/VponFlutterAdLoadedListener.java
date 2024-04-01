package io.flutter.plugins.vponmobileads;

import com.vpon.ads.VponAdListener;

import java.lang.ref.WeakReference;

interface VponFlutterAdLoadedListener {
    void onAdLoaded();

    class VponFlutterAdListener extends VponAdListener {

        protected final int adId;
        protected final VponAdInstanceManager adInstanceManager;
        VponFlutterAdListener(int adId, VponAdInstanceManager adInstanceManager){
            this.adId = adId;
            this.adInstanceManager = adInstanceManager;
        }

    }

    class VponFlutterBannerAdListener extends VponFlutterAdListener {

        final WeakReference<VponFlutterAdLoadedListener> adLoadedListenerWeakReference;
        VponFlutterBannerAdListener(int adId, VponAdInstanceManager adInstanceManager
                , VponFlutterAdLoadedListener vponFlutterAdLoadedListener){
            super(adId, adInstanceManager);
            adLoadedListenerWeakReference = new WeakReference<>(vponFlutterAdLoadedListener);
        }

        @Override
        public void onAdLoaded() {
            adLoadedListenerWeakReference.get().onAdLoaded();
        }
    }

}
