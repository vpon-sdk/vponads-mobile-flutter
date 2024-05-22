package io.flutter.plugins.vponmobileads

import com.vpon.ads.VponFullScreenContentCallback

internal class VponFlutterFullScreenContentCallback(
    private val vponAdInstanceManager: VponAdInstanceManager,
    private val adid: Int
) : VponFullScreenContentCallback() {

    override fun onAdClicked() {
        vponAdInstanceManager.onAdClicked(adid)
    }

    override fun onAdDismissedFullScreenContent() {
        vponAdInstanceManager.onAdDismissedFullScreenContent(adid)
    }

    override fun onAdFailedToShowFullScreenContent(errorCode: Int) {
        vponAdInstanceManager.onFailedToShowFullScreenContent(adid, errorCode)
    }

    override fun onAdImpression() {
        vponAdInstanceManager.onAdImpression(adid)
    }

    override fun onAdShowedFullScreenContent() {
        vponAdInstanceManager.onAdShowedFullScreenContent(adid)
    }
}
