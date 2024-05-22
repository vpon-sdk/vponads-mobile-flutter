package io.flutter.plugins.vponmobileads

import android.content.Context
import android.util.Log
import com.vpon.ads.VponAdListener
import com.vpon.ads.VponAdLoader
import com.vpon.ads.VponAdRequest
import com.vpon.ads.VponInterstitialAd
import com.vpon.ads.VponInterstitialAdLoadCallback
import com.vpon.ads.VponNativeAd

internal class VponFlutterAdLoader(private val context: Context) {

    fun loadInterstitial(
        licenseKey: String,
        vponAdRequest: VponAdRequest,
        vponInterstitialAdLoadCallback: VponInterstitialAdLoadCallback
    ) {
        Log.d(TAG, "loadInterstitial invoked!!")
        VponInterstitialAd.load(context, licenseKey, vponAdRequest, vponInterstitialAdLoadCallback)
    }

    fun loadNativeAd(
        licenseKey: String,
        onNativeAdLoadedListener: VponNativeAd.OnNativeAdLoadedListener,
        adListener: VponAdListener,
        vponAdRequest: VponAdRequest
    ) {
        VponAdLoader.Builder(context, licenseKey).withAdListener(adListener)
            .forNativeAd(onNativeAdLoadedListener).build().loadAd(vponAdRequest)
    }

    companion object {
        private const val TAG = "VponFlutterAdLoader"
    }
}
