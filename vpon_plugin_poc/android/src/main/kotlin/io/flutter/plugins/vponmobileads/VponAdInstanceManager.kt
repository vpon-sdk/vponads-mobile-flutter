package io.flutter.plugins.vponmobileads

import android.os.Handler
import android.os.Looper
import android.util.Log
import com.vpon.ads.VponAdRequest
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.vponmobileads.VponFlutterAd.VponFlutterOverlayAd
import java.util.Locale

internal class VponAdInstanceManager(private val channelToDart: MethodChannel) {

    private val ads = HashMap<Int, VponFlutterAd>()

    fun showAd(adId: Int) {
        Log.d(TAG, "showAd($adId) invoked!!")
        if (!ads.containsKey(adId)) {
            Log.e(TAG, "BP-1")
            return
        }
        Log.e(TAG, "BP-2")
        val ad = ads[adId] as VponFlutterOverlayAd?
        Log.e(TAG, "ad is null ? "+(ad == null))
        ad?.show()
        Log.e(TAG, "BP-3")
    }

    fun onAdLoaded(vponFlutterAd: VponFlutterAd) {
        Log.d(TAG, "VponAdInstanceManager invoke onAdEvent onAdLoaded")

        trackAd(vponFlutterAd.adId, vponFlutterAd)

        val arguments: MutableMap<Any, Any> = HashMap()
        arguments[Constants.CHANNEL_ARGUMENT_ADID] = vponFlutterAd.adId
        arguments[Constants.CHANNEL_ARGUMENT_EVENT_NAME] = "onAdLoaded"
        invokeOnAdEvent(arguments)
    }

    fun onAdFailedToLoad(
        vponFlutterAd: VponFlutterAd,
        vponErrorCode: VponAdRequest.VponErrorCode
    ) {
        Log.d(
            TAG, "VponAdInstanceManager invoke onAdEvent " +
                    "onAdFailedToLoad($vponErrorCode.errorCode)"
        )
        val arguments: MutableMap<Any, Any> = HashMap()
        arguments[Constants.CHANNEL_ARGUMENT_ADID] = vponFlutterAd.adId
        val errors: MutableMap<Any, Any> = HashMap()
        errors[Constants.CHANNEL_ARGUMENT_ERROR_DESCRIPTION] =
            vponErrorCode.errorDescription!!
        errors[Constants.CHANNEL_ARGUMENT_ERROR_CODE] =
            vponErrorCode.errorCode
        arguments[Constants.CHANNEL_ARGUMENT_LOAD_AD_ERROR] =
            errors
        invokeOnAdEvent(arguments)
    }

    fun onFailedToShowFullScreenContent(
        adId: Int,
        vponErrorCode: Int
    ) {
        Log.d(
            TAG, "VponAdInstanceManager invoke onAdEvent " +
                    "onFailedToShowFullScreenContent($vponErrorCode)"
        )
        val arguments: MutableMap<Any, Any> = java.util.HashMap()
        arguments[Constants.CHANNEL_ARGUMENT_ADID] = adId
        val errors: MutableMap<Any, Any> = java.util.HashMap()
        errors[Constants.CHANNEL_ARGUMENT_ERROR_DESCRIPTION] = "onFailedToShowFullScreenContent"
        errors[Constants.CHANNEL_ARGUMENT_ERROR_CODE] =
            vponErrorCode
        arguments[Constants.CHANNEL_ARGUMENT_EVENT_NAME] = "onFailedToShowFullScreenContent"
        arguments[Constants.CHANNEL_ARGUMENT_ERROR] = errors
        invokeOnAdEvent(arguments)
    }

    fun onAdImpression(adId: Int) {
        Log.d(TAG, "VponAdInstanceManager invoke onAdEvent onAdImpression")
        val arguments: MutableMap<Any, Any> = HashMap()
        arguments[Constants.CHANNEL_ARGUMENT_ADID] = adId
        arguments[Constants.CHANNEL_ARGUMENT_EVENT_NAME] = "onAdImpression"
        invokeOnAdEvent(arguments)
    }

    fun onAdClicked(adId: Int) {
        Log.d(TAG, "VponAdInstanceManager invoke onAdEvent onAdClicked")
        val arguments: MutableMap<Any, Any> = HashMap()
        arguments[Constants.CHANNEL_ARGUMENT_ADID] = adId
        arguments[Constants.CHANNEL_ARGUMENT_EVENT_NAME] = "onAdClicked"
        invokeOnAdEvent(arguments)
    }

    fun onAdShowedFullScreenContent(adId: Int) {
        Log.d(
            TAG,
            "VponAdInstanceManager invoke onAdEvent onAdShowedFullScreenContent"
        )
        val arguments: MutableMap<Any, Any> = HashMap()
        arguments[Constants.CHANNEL_ARGUMENT_ADID] = adId
        arguments[Constants.CHANNEL_ARGUMENT_EVENT_NAME] = "onAdShowedFullScreenContent"
        invokeOnAdEvent(arguments)
    }

    fun onAdDismissedFullScreenContent(adId: Int) {
        Log.d(
            TAG,
            "VponAdInstanceManager invoke onAdEvent onAdDismissedFullScreenContent"
        )
        val arguments: MutableMap<Any, Any> = HashMap()
        arguments[Constants.CHANNEL_ARGUMENT_ADID] = adId
        arguments[Constants.CHANNEL_ARGUMENT_EVENT_NAME] = "onAdDismissedFullScreenContent"
        invokeOnAdEvent(arguments)
    }

    private fun trackAd(adId: Int, vponFlutterAd: VponFlutterAd) {
        Log.d(TAG, "trackAd($adId) invoked!!")
        require(ads[adId] == null) {
            String.format(
                Locale.TAIWAN,
                "Ad for following adId already exists: %d",
                adId
            )
        }
        ads[adId] = vponFlutterAd
    }

    private fun invokeOnAdEvent(arguments: Map<Any, Any>) {
        Handler(Looper.getMainLooper())
            .post {
                channelToDart
                    .invokeMethod(
                        Constants.CHANNEL_ARGUMENT_ON_AD_EVENT,
                        arguments
                    )
            }
    }

    fun disposeAd(adId: Int) {
        if (!ads.containsKey(adId)) {
            return
        }
        val ad = ads[adId]
        ad?.dispose()
        ads.remove(adId)
    }

    fun disposeAllAds() {
        for ((_, value) in ads) {
            value.dispose()
        }
        ads.clear()
    }

    fun adForId(id: Int): VponFlutterAd? {
        return ads[id]
    }

    companion object {
        private const val TAG = "VponAdInstanceManager"
    }
}
