package io.flutter.plugins.vponmobileads

import android.util.Log
import com.vpon.ads.VponAdRequest
import com.vpon.ads.VponInterstitialAd
import com.vpon.ads.VponInterstitialAdLoadCallback
import java.lang.ref.WeakReference

internal class VponFlutterInterstitialAd(
    adId: Int,
    private val adInstanceManager: VponAdInstanceManager,
    private val licenseKey: String,
    private val flutterAdRequest: VponFlutterAdRequest, private val adLoader: VponFlutterAdLoader
) : VponFlutterAd.VponFlutterOverlayAd(adId) {

    private var vponInterstitialAd: VponInterstitialAd? = null

    override fun load() {
        Log.d(TAG, "load invoked!!")
        adLoader.loadInterstitial(
            licenseKey,
            flutterAdRequest.asVponAdRequest(),
            DelegatingInterstitialAdLoadCallback(this)
        )
    }

    override fun show() {
        Log.d(TAG, "show invoked!!")
        if (vponInterstitialAd == null) {
            Log.d(
                TAG,
                "Error showing interstitial - the interstitial ad wasn't loaded yet."
            )
            return
        }
        vponInterstitialAd?.fullScreenContentCallback =
            VponFlutterFullScreenContentCallback(adInstanceManager, adId)
    }

    override fun dispose() {
        vponInterstitialAd = null
    }

    private fun onAdLoaded(vponInterstitialAd: VponInterstitialAd) {
        Log.d(TAG, "onAdLoaded invoked!!")
        this.vponInterstitialAd = vponInterstitialAd
        adInstanceManager.onAdLoaded(this)
    }

    private fun onAdFailedToLoad(vponErrorCode: VponAdRequest.VponErrorCode) {
        Log.d(
            TAG,
            "onAdFailedToLoad($vponErrorCode.errorCode " +
                    "/$vponErrorCode.errorDescription) invoked!!"

        )
        adInstanceManager.onAdFailedToLoad(this, vponErrorCode)
    }

    private class DelegatingInterstitialAdLoadCallback(
        vponFlutterInterstitialAd: VponFlutterInterstitialAd
    ) :
        VponInterstitialAdLoadCallback() {

        val delegate = WeakReference(vponFlutterInterstitialAd)

        override fun onAdFailedToLoad(adError: VponAdRequest.VponErrorCode) {
            delegate.get()?.onAdFailedToLoad(adError)
        }

        override fun onAdLoaded(ad: VponInterstitialAd) {
            delegate.get()?.onAdLoaded(ad)
        }

    }

    companion object {
        private const val TAG = "VFlutterInterstitialAd"
    }
}