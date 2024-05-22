package io.flutter.plugins.vponmobileads

import android.content.Context
import com.vpon.ads.VponBanner
import io.flutter.plugin.platform.PlatformView

internal class VponFlutterBannerAd(
    private val context: Context,
    adId: Int,
    private val adInstanceManager: VponAdInstanceManager,
    private val licenseKey: String,
    private val adRequest: VponFlutterAdRequest, private val flutterAdSize: VponFlutterAdSize
) : VponFlutterAd(adId), VponFlutterAdLoadedListener {

    private var vponBanner: VponBanner? = null


    override fun load() {
        vponBanner = VponBanner(context)
        vponBanner?.let {
            it.licenseKey = licenseKey
            it.adSize = flutterAdSize.vponAdSize
            it.setAdListener(
                VponFlutterBannerAdListener(
                    adId, adInstanceManager, this
                )
            )
            it.loadAd(adRequest.asVponAdRequest())
        }
    }

    override fun dispose() {
        vponBanner?.destroy()
        vponBanner = null
    }

    override fun onAdLoaded() {
        vponBanner?.let { adInstanceManager.onAdLoaded(this) }
    }

    override fun getPlatformView(): PlatformView? {
        vponBanner?.let { return VponFlutterPlatformView(it) }
        return super.getPlatformView()
    }
}
