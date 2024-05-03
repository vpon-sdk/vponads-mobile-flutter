package io.flutter.plugins.vponmobileads;

import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.vpon.ads.VponAdListener;
import com.vpon.ads.VponNativeAd;

import io.flutter.plugin.platform.PlatformView;

class VponFlutterNativeAd extends VponFlutterAd {

    @NonNull
    private final VponAdInstanceManager manager;
    @NonNull
    private final String licenseKey;
    @NonNull
    private final VponMobileAdsPlugin.NativeAdFactory adFactory;
    @NonNull
    private final VponFlutterAdLoader flutterAdLoader;
    @NonNull
    private final VponFlutterAdRequest request;
    @Nullable
    private View nativeAdView;

    VponFlutterNativeAd(
            int adId,
            @NonNull VponAdInstanceManager manager,
            @NonNull String licenseKey,
            @NonNull VponMobileAdsPlugin.NativeAdFactory adFactory,
            @NonNull VponFlutterAdRequest request,
            @NonNull VponFlutterAdLoader flutterAdLoader) {
        super(adId);
        this.manager = manager;
        this.licenseKey = licenseKey;
        this.adFactory = adFactory;
        this.request = request;
        this.flutterAdLoader = flutterAdLoader;
    }

    @Override
    void load() {
        final VponNativeAd.OnNativeAdLoadedListener loadedListener =
                new VponFlutterNativeAdLoadedListener(this);
        final VponAdListener adListener = new VponFlutterNativeAdListener(adId, manager);
        flutterAdLoader.loadNativeAd(licenseKey, loadedListener, adListener
                , request.asVponAdRequest());
    }

    @Override
    void dispose() {
        nativeAdView = null;
    }

    void onNativeAdLoaded(VponNativeAd vponNativeAd) {
        nativeAdView = adFactory.createNativeAd(vponNativeAd);
        manager.onAdLoaded(this);
    }

    @Override
    @Nullable
    public PlatformView getPlatformView() {
        if (nativeAdView != null) {
            return new VponFlutterPlatformView(nativeAdView);
        }
        return null;
    }

    static class Builder {

        @Nullable
        private VponAdInstanceManager manager;
        @Nullable
        private String licenseKey;
        @Nullable
        private VponMobileAdsPlugin.NativeAdFactory adFactory;
        @Nullable
        private VponFlutterAdRequest request;
        @Nullable
        private Integer id;
        @Nullable
        private VponFlutterAdLoader flutterAdLoader;

        public Builder setManager(@NonNull VponAdInstanceManager manager) {
            this.manager = manager;
            return this;
        }
        public Builder setAdFactory(@NonNull VponMobileAdsPlugin.NativeAdFactory adFactory) {
            this.adFactory = adFactory;
            return this;
        }

        public Builder setId(int id) {
            this.id = id;
            return this;
        }

        public Builder setLicenseKey(@NonNull String licenseKey) {
            this.licenseKey = licenseKey;
            return this;
        }

        public Builder setRequest(@NonNull VponFlutterAdRequest request) {
            this.request = request;
            return this;
        }

        public Builder setFlutterAdLoader(@NonNull VponFlutterAdLoader flutterAdLoader) {
            this.flutterAdLoader = flutterAdLoader;
            return this;
        }

        VponFlutterNativeAd build() {
            if (manager == null) {
                throw new IllegalStateException("VponAdInstanceManager cannot be null.");
            } else if (licenseKey == null) {
                throw new IllegalStateException("licenseKey cannot be null.");
            } else if (adFactory == null) {
                throw new IllegalStateException("NativeAdFactory cannot be null.");
            } else if (request == null) {
                throw new IllegalStateException("adRequest must be non-null.");
            }

            final VponFlutterNativeAd nativeAd;
            nativeAd =
                    new VponFlutterNativeAd(
                            id,
                            manager,
                            licenseKey,
                            adFactory,
                            request,
                            flutterAdLoader);
            return nativeAd;
        }
    }
}
