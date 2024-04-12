package com.example.vpon_plugin_poc_example

import android.annotation.SuppressLint
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import com.vpon.ads.VponAdLoader
import com.vpon.ads.VponMediaView
import com.vpon.ads.VponNativeAd
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.vponmobileads.VponMobileAdsPlugin
import java.lang.ref.WeakReference

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        flutterEngine.plugins.add(VponMobileAdsPlugin())
        super.configureFlutterEngine(flutterEngine)
        VponMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "VponNativeAdFactory",
            NativeAdFactoryExample(layoutInflater)
        )
    }

    private class NativeAdFactoryExample(private var layoutInflater: LayoutInflater) :
        VponMobileAdsPlugin.NativeAdFactory {

        @SuppressLint("InflateParams")
        override fun createNativeAd(vponNativeAd: VponNativeAd): View {
            val adView = layoutInflater.inflate(R.layout.layout_vponmobileads_native_ad_template
                , null, false)
            val adContainer = adView.findViewById<ViewGroup>(R.id.ad_container)
            val nativeAdIcon = adView.findViewById<ImageView>(R.id.ad_app_icon)
            val nativeAdTitle = adView.findViewById<TextView>(R.id.ad_headline)
            val nativeAdBody = adView.findViewById<TextView>(R.id.ad_body)
            val nativeMediaContainer = adView.findViewById<FrameLayout>(R.id.ad_media_container)
            val nativeAdCallToAction = adView.findViewById<Button>(R.id.ad_call_to_action)
            nativeAdCallToAction?.tag = "TagCallToAction"
            val weakContextReferences = WeakReference(adView.context)
            nativeMediaContainer?.let {
                val nativeAdMedia = VponMediaView(weakContextReferences.get())
                it.addView(
                    nativeAdMedia, ViewGroup.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT
                    )
                )
                nativeAdMedia.setNativeAd(vponNativeAd)
            }
            nativeAdCallToAction.text = vponNativeAd.callToAction
            nativeAdTitle.text = vponNativeAd.title
            nativeAdBody.text = vponNativeAd.body
            VponAdLoader.downloadAndDisplayImage(vponNativeAd.icon, nativeAdIcon)
            vponNativeAd.registerViewForInteraction(adContainer)
            return adView
        }
    }
}
