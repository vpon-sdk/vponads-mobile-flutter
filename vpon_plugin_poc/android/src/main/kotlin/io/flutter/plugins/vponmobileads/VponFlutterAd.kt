package io.flutter.plugins.vponmobileads;

import androidx.annotation.Nullable;

import io.flutter.plugin.platform.PlatformView;

abstract class VponFlutterAd {

    protected final int adId;

    VponFlutterAd(int adId) {
        this.adId = adId;
    }

    abstract void load();
    abstract void dispose();

    @Nullable
    PlatformView getPlatformView() {
        return null;
    }

    abstract static class VponFlutterOverlayAd extends VponFlutterAd {

        abstract void show();

        VponFlutterOverlayAd(int adId) {
            super(adId);
        }
    }
}
