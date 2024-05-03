package io.flutter.plugins.vponmobileads;

import android.content.Context;

import androidx.annotation.Nullable;

import com.vpon.ads.VponBanner;

import io.flutter.plugin.platform.PlatformView;

class VponFlutterBannerAd extends VponFlutterAd implements VponFlutterAdLoadedListener {

    private final String licenseKey;
    private final VponFlutterAdRequest flutterAdRequest;
    private final VponFlutterAdSize flutterAdSize;
    private final VponAdInstanceManager adInstanceManager;
    private final Context context;
    private VponBanner vponBanner = null;

    VponFlutterBannerAd(Context context, int adId, VponAdInstanceManager adInstanceManager
            , String licenseKey
            , VponFlutterAdRequest adRequest, VponFlutterAdSize size) {
        super(adId);
        this.licenseKey = licenseKey;
        this.flutterAdRequest = adRequest;
        this.flutterAdSize = size;

        this.context = context;
        this.adInstanceManager = adInstanceManager;
    }

    @Override
    void load() {
        vponBanner = new VponBanner(context);
        vponBanner.setLicenseKey(licenseKey);
        vponBanner.setAdSize(flutterAdSize.getAdSize());
        vponBanner.setAdListener(new VponFlutterBannerAdListener(adId, adInstanceManager
                , this));
        vponBanner.loadAd(flutterAdRequest.asVponAdRequest());
    }

    @Override
    void dispose() {
        if (vponBanner != null) {
            vponBanner.destroy();
            vponBanner = null;
        }
    }

    @Override
    public void onAdLoaded() {
        if (vponBanner != null) {
            adInstanceManager.onAdLoaded(this);
        }
    }

    @Nullable
    @Override
    PlatformView getPlatformView() {
        if(vponBanner != null){
            return new VponFlutterPlatformView(vponBanner);
        }
        return super.getPlatformView();
    }
}
