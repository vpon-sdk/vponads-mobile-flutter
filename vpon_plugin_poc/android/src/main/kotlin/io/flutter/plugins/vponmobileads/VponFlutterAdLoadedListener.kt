package io.flutter.plugins.vponmobileads

import com.vpon.ads.VponAdListener
import com.vpon.ads.VponAdRequest
import com.vpon.ads.VponNativeAd
import java.lang.ref.WeakReference

interface VponFlutterAdLoadedListener {
    fun onAdLoaded()
}

internal open class VponFlutterAdListener(
    protected val adId: Int,
    protected val vponAdInstanceManager: VponAdInstanceManager
) : VponAdListener()

internal class VponFlutterBannerAdListener(
    adId: Int,
    vponAdInstanceManager: VponAdInstanceManager,
    vponFlutterAdLoadedListener: VponFlutterAdLoadedListener
) : VponFlutterAdListener(adId, vponAdInstanceManager) {
    private val adLoadedListenerWeakReference = WeakReference(vponFlutterAdLoadedListener)

    override fun onAdLoaded() {
        adLoadedListenerWeakReference.get()?.onAdLoaded()
    }
    override fun onAdFailedToLoad(errorCode: Int) {
        var vponErrorCode : VponAdRequest.VponErrorCode = VponAdRequest.VponErrorCode.NO_FILL
        when (errorCode) {
            0 -> vponErrorCode = VponAdRequest.VponErrorCode.INTERNAL_ERROR
            1 -> vponErrorCode = VponAdRequest.VponErrorCode.INVALID_REQUEST
            2 -> vponErrorCode = VponAdRequest.VponErrorCode.NETWORK_ERROR
            3 -> vponErrorCode = VponAdRequest.VponErrorCode.NO_FILL
        }
        vponAdInstanceManager.onAdFailedToLoad(adId,vponErrorCode)
    }
}

internal class VponFlutterNativeAdListener(
    adId: Int,
    vponAdInstanceManager: VponAdInstanceManager
) : VponFlutterAdListener(adId, vponAdInstanceManager)

internal class VponFlutterNativeAdLoadedListener(flutterNativeAd: VponFlutterNativeAd) :
    VponNativeAd.OnNativeAdLoadedListener() {
    private val nativeAdWeakReference = WeakReference(flutterNativeAd)

    override fun onNativeAdLoaded(nativeAd: VponNativeAd?) {
        nativeAdWeakReference.get()?.onNativeAdLoaded(nativeAd)
    }
}