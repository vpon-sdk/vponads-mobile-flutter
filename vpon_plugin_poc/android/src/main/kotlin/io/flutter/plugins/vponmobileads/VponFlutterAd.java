package io.flutter.plugins.vponmobileads;

abstract class VponFlutterAd {

    protected final int adId;

    VponFlutterAd(int adId) {
        this.adId = adId;
    }

    abstract void load();
    abstract void dispose();

    abstract static class VponFlutterOverlayAd extends VponFlutterAd {

        abstract void show();

        VponFlutterOverlayAd(int adId) {
            super(adId);
        }
    }
}
