package io.flutter.plugins.vponmobileads;

import androidx.annotation.NonNull;

import com.vpon.ads.VponFullScreenContentCallback;

class VponFlutterFullScreenContentCallback extends VponFullScreenContentCallback {

    @NonNull protected final VponAdInstanceManager manager;

    protected final int adId;

    VponFlutterFullScreenContentCallback(@NonNull VponAdInstanceManager manager, int adId) {
        this.manager = manager;
        this.adId = adId;
    }

    @Override
    public void onAdClicked() {
        manager.onAdClicked(adId);
    }

    @Override
    public void onAdDismissedFullScreenContent() {
        manager.onAdDismissedFullScreenContent(adId);
    }

    @Override
    public void onAdFailedToShowFullScreenContent(int errorCode) {
        manager.onFailedToShowFullScreenContent(adId, errorCode);
    }

    @Override
    public void onAdImpression() {
        manager.onAdImpression(adId);
    }

    @Override
    public void onAdShowedFullScreenContent() {
        manager.onAdShowedFullScreenContent(adId);
    }
}
