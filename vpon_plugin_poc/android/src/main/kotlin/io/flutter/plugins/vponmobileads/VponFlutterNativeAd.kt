package io.flutter.plugins.vponmobileads

import android.view.View
import com.vpon.ads.VponNativeAd

internal class VponFlutterNativeAd(
    adId: Int,
    private val manager: VponAdInstanceManager,
    private val licenseKey: String,
    private val adFactory: VponMobileAdsPlugin.NativeAdFactory,
    private val request: VponFlutterAdRequest,
    private val flutterAdLoader: VponFlutterAdLoader
) : VponFlutterAd(adId) {

    private var nativeAdView: View? = null

    override fun load() {
        flutterAdLoader.loadNativeAd(
            licenseKey,
            VponFlutterNativeAdLoadedListener(this),
            VponFlutterNativeAdListener(adId, manager),
            request.asVponAdRequest()
        )
    }

    override fun dispose() {
        nativeAdView = null
    }

    fun onNativeAdLoaded(vponNativeAd: VponNativeAd?) {
        nativeAdView = adFactory.createNativeAd(vponNativeAd!!)
        manager.onAdLoaded(this)
    }

    internal class Builder {
        private var manager: VponAdInstanceManager? = null
        private var adFactory: VponMobileAdsPlugin.NativeAdFactory? = null
        private var licenseKey: String? = null
        private var request: VponFlutterAdRequest? = null
        private var adId: Int? = null
        private var flutterAdLoader: VponFlutterAdLoader? = null

        fun setManager(manager: VponAdInstanceManager?) = apply { this.manager = manager }
        fun setAdFactory(adFactory: VponMobileAdsPlugin.NativeAdFactory?) =
            apply { this.adFactory = adFactory }

        fun setId(adId: Int?) = apply { this.adId = adId }
        fun setLicenseKey(licenseKey: String?) = apply { this.licenseKey = licenseKey }
        fun setRequest(request: VponFlutterAdRequest?) = apply { this.request = request }
        fun setFlutterAdLoader(flutterAdLoader: VponFlutterAdLoader?) =
            apply { this.flutterAdLoader = flutterAdLoader }

        fun build(): VponFlutterNativeAd {
            require(adId == null) { "adId cannot be null." }
            require(manager == null) { "VponAdInstanceManager cannot be null." }
            require(licenseKey == null) { "licenseKey cannot be null." }
            require(adFactory == null) { "NativeAdFactory cannot be null." }
            require(request == null) { "VponFlutterAdRequest cannot be null." }
            require(flutterAdLoader == null) { "VponFlutterAdLoader cannot be null." }
            return VponFlutterNativeAd(
                adId!!,
                manager!!,
                licenseKey!!,
                adFactory!!,
                request!!,
                flutterAdLoader!!
            )
        }
    }

}
